# Code Coverage Setup

## Added Files

- `custom-app/backend/jest.config.js` — Jest configuration with coverage thresholds
- `custom-app/backend/__tests__/health.test.js` — Example test suite
- `custom-app/backend/.gitignore` — Excludes coverage directories

## Updated Files

- `custom-app/backend/package.json` — Added Jest, Supertest, and test scripts
- `.github/workflows/docker.yml` — Added coverage job

## Features

### Local Testing
```bash
cd custom-app/backend
npm install
npm run test           # Run tests once
npm run test:cov       # Run with coverage report
npm run test:watch     # Watch mode for development
```

### Coverage Thresholds
Enforced minimums (fails if not met):
- **Branches**: 70%
- **Functions**: 70%
- **Lines**: 70%
- **Statements**: 70%

Adjust in `jest.config.js` if needed.

### CI/CD Integration

**Coverage Job** runs on all push/PR events:
1. Sets up Node.js 18 with npm caching
2. Installs dependencies
3. Runs `npm run test:cov`
4. Uploads results to Codecov.io (optional, set up at codecov.io)
5. **On PRs**: Comments directly on PR with coverage report

### Coverage Badge for README

Add to your `README.md`:
```markdown
[![codecov](https://codecov.io/gh/YOUR_GITHUB_ORG/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_GITHUB_ORG/YOUR_REPO)
```

Or if using Codecov without a badge:
```markdown
![Tests](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/docker.yml/badge.svg)
```

## Next: Expand Tests

Add more tests to `__tests__/`:
```bash
# API endpoint tests
npm install --save-dev @types/node

# Database tests (requires test database)
# Mock tests using Jest mocks
```

Example test structure:
```javascript
describe('API Endpoints', () => {
  test('POST /api/data saves to database', () => {
    // Your test
  });
});
```

## Troubleshooting

**Coverage not uploading to Codecov?**
- Sign up at codecov.io
- Link your GitHub repo (automatic)
- Add CODECOV_TOKEN secret if needed (usually not for public repos)

**PR comment not appearing?**
- Verify workflow has read/write permissions on PR
- Check romeovs/lcov-reporter-action@v0.3.1 is installed

**Tests not running in CI?**
- Ensure `npm install` runs before `npm run test:cov`
- Check Node.js version in workflow matches `package.json` engines field
