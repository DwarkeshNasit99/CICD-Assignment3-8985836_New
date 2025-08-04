const { app } = require('@azure/functions');

/**
 * HTTP Trigger Azure Function - Hello World
 * This function responds to HTTP requests with a "Hello, World!" message
 */
app.http('httpTrigger', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    route: 'hello',
    handler: async (request, context) => {
        context.log('HTTP trigger function processed a request.');

        // Get query parameters
        const name = request.query.get('name');
        const responseMessage = name 
            ? `Hello, ${name}! This Azure Function was deployed using Jenkins CI/CD Pipeline.`
            : 'Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.';

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            jsonBody: {
                message: responseMessage,
                timestamp: new Date().toISOString(),
                environment: process.env.AZURE_FUNCTIONS_ENVIRONMENT || 'local',
                nodeVersion: process.version
            }
        };
    }
});

module.exports = app;