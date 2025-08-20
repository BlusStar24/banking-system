module.exports = {
    apps: [
        {
            name: 'aspnet',
            script: 'dotnet',
            args: 'transfer-service.dll',
            cwd: '/app',
            interpreter: 'none'
        },
        {
            name: 'workflow',
            script: '/app/workflow-api/server.js'
        }
    ]
};
