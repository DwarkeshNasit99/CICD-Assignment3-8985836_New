const { app } = require('@azure/functions');

/**
 * Azure Functions v4 Programming Model
 * All functions defined in this single entry point file
 * Compatible with Node.js 20 and Azure Functions Runtime 4.25+
 */

// HTTP Trigger Function - Hello World
app.http('httpTrigger', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    route: 'hello',
    handler: async (request, context) => {
        context.log('HTTP trigger function processed a request.');

        // Get query parameters - v4 model syntax
        const name = request.query.get('name');
        
        let responseMessage;
        if (name) {
            responseMessage = `Hello, ${name}! This Azure Function was deployed using Jenkins CI/CD Pipeline.`;
        } else {
            responseMessage = 'Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.';
        }

        context.log(`Generated response: ${responseMessage}`);

        // Return response - v4 model format
        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            jsonBody: {
                message: responseMessage,
                timestamp: new Date().toISOString(),
                environment: process.env.AZURE_FUNCTIONS_ENVIRONMENT || 'production',
                nodeVersion: process.version,
                functionRuntime: 'Azure Functions v4',
                programmingModel: 'Node.js v4',
                deploymentMethod: 'Jenkins CI/CD Pipeline'
            }
        };
    }
});