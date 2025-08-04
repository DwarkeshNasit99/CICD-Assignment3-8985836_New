/**
 * Azure Functions v4 Entry Point
 * This file imports and registers all functions
 */

// Import all function definitions
require('./functions/httpTrigger');

// The functions are automatically registered when imported
// No additional export needed for Azure Functions v4