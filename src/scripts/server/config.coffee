class Config
    @Const:
        CONFIG_SERVICE_ADDRESS: 'tcp://192.168.221.11:12345'
        CONFIG_SERVICE_NAME: 'config-service'
        DB_CONFIG_SERVICE: 'postgres-config'
        SCHEMA: ''
        TABLE_REGEXP: "KNA1"

# TODO ZMQ CONSTANTS
# Refactor

module.exports = Config
