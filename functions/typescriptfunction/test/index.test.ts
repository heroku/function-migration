import 'mocha';
import { expect } from 'chai';
import createSandbox from 'sinon/lib/sinon/create-sandbox.js';
import SinonSandbox from 'sinon/lib/sinon/sandbox.js';

import execute from '../index.js';

/**
 * Typescriptfunction unit tests.
 */
describe('Unit Tests', () => {
  let sandbox: SinonSandbox;
  let mockContext;
  let mockLogger;
  let mockEvent;
  let accounts;

  beforeEach(() => {
    mockEvent = { id: {}, type: {}, source: {} };
    mockContext = {
      org: {
        dataApi: { query: () => undefined },
      },
      logger: { info: () => undefined },
    };

    mockLogger = mockContext.logger;
    sandbox = createSandbox();

    sandbox.stub(mockContext.org.dataApi, 'query');
    sandbox.stub(mockLogger, 'info');

    accounts = {
      totalSize: 3,
      done: true,
      records: [
        {
          type: 'Account',
          fields: { Name: 'Global Media' },
        },
        {
          type: 'Account',
          fields: { Name: 'Acme' },
        },
        {
          type: 'Account',
          fields: { Name: 'salesforce.com' },
        },
      ],
    };

    mockContext.org.dataApi.query.callsFake(() => {
      return Promise.resolve(accounts);
    });
  });

  afterEach(() => {
    sandbox.restore();
  });

  it('Invoke Typescriptfunction', async () => {
    const results = await execute(mockEvent, mockContext, mockLogger);

    expect(mockContext.org.dataApi.query.callCount).to.be.eql(1);
    expect(mockLogger.info.callCount).to.be.eql(2);
    expect(results).to.be.not.undefined;
    expect(results).has.property('length');
    expect(results.length).to.be.eql(accounts.totalSize);
  });
});
