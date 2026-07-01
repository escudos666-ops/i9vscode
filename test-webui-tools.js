#!/usr/bin/env node

const puppeteer = require('puppeteer');
const http = require('http');

const WEBUI_URL = 'http://webui-service:8080';
const API_BASE = 'http://webui-service:8080/api/v1';

function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({ 
            status: res.statusCode,
            headers: res.headers,
            body: data ? JSON.parse(data) : null 
          });
        } catch (e) {
          resolve({ 
            status: res.statusCode,
            headers: res.headers,
            body: data 
          });
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

async function testWebUITools() {
  console.log('🚀 Testing WebUI Tools & LLM Integration...\n');

  try {
    // Test 1: Health check
    console.log('1️⃣ Health Check');
    const health = await makeRequest(`${WEBUI_URL}/api/health`);
    console.log(`Status: ${health.status}`);
    console.log(`Response: ${JSON.stringify(health.body)}\n`);

    // Test 2: Get models
    console.log('2️⃣ Available Models');
    const models = await makeRequest(`${API_BASE}/models`);
    console.log(`Status: ${models.status}`);
    if (models.status === 200) {
      console.log(`✓ Models:`, JSON.stringify(models.body).substring(0, 300));
    } else {
      console.log(`⚠️ ${models.status} response - ${typeof models.body === 'string' ? models.body.substring(0, 150) : JSON.stringify(models.body)}`);
    }
    console.log();

    // Test 3: Browser-based chat test
    console.log('3️⃣ Browser-based Interaction Test\n');
    
    let browser;
    browser = await puppeteer.launch({
      executablePath: '/usr/bin/chromium-browser',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
      ]
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });

    console.log('Navigating to WebUI...');
    await page.goto(WEBUI_URL, { waitUntil: 'networkidle2', timeout: 30000 });
    console.log('✓ Loaded\n');

    // Wait for content
    await new Promise(r => setTimeout(r, 2000));

    // Try to get page state
    const pageState = await page.evaluate(() => {
      return {
        readyState: document.readyState,
        title: document.title,
        bodyText: document.body.innerText.substring(0, 500),
        isLoggedIn: !window.location.href.includes('/auth'),
        hasChat: !!document.querySelector('[class*="chat"]'),
      };
    });

    console.log('Page State:');
    Object.entries(pageState).forEach(([k, v]) => {
      console.log(`  ${k}: ${typeof v === 'string' && v.length > 50 ? v.substring(0, 50) + '...' : v}`);
    });
    console.log();

    // Test 4: Check for tool integrations
    console.log('4️⃣ Tool Integration Check\n');
    
    const toolsCheck = await page.evaluate(() => {
      const tools = {
        shopify: !![...document.body.innerText].some((_, i, arr) => 
          arr.slice(i, i+7).join('') === 'Shopify'),
        postgresql: !!document.body.innerText.includes('postgres'),
        ollama: !!document.body.innerText.includes('ollama'),
        integrations: !!document.body.innerText.toLowerCase().includes('integration'),
        tools: !!document.body.innerText.toLowerCase().includes('tool'),
      };
      return tools;
    });

    console.log('Integration references found:');
    Object.entries(toolsCheck).forEach(([tool, found]) => {
      console.log(`  ${found ? '✓' : '✗'} ${tool}`);
    });
    console.log();

    // Test 5: Screenshot
    await page.screenshot({ path: '/tmp/webui-tools-test.png', fullPage: true });
    console.log('📸 Screenshot saved: /tmp/webui-tools-test.png\n');

    await browser.close();

    // Test 6: Check Ollama integration
    console.log('5️⃣ Ollama Integration Check\n');
    try {
      const ollamaModels = await makeRequest('http://ollama-service:11434/api/tags');
      console.log(`Ollama Status: ${ollamaModels.status}`);
      if (ollamaModels.body && ollamaModels.body.models) {
        console.log(`✓ Models available: ${ollamaModels.body.models.length}`);
        console.log(`  Models: ${ollamaModels.body.models.slice(0, 3).map(m => m.name).join(', ')}`);
      }
    } catch (e) {
      console.log(`✗ Ollama check failed: ${e.message}`);
    }
    console.log();

    console.log('✅ Test Suite Completed!\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

testWebUITools();
