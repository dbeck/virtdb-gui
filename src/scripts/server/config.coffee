class Config
    @Values:
        GUI_ENDPOINT_NAME: "virtdb-gui"
        CONFIG_SERVICE_ADDRESS: "tcp://192.168.221.11:12345"
        CONFIG_SERVICE_NAME: "config-service"
        DB_CONFIG_SERVICE: "postgres-config"
        SCHEMA: ""

module.exports = Config
