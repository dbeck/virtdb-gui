class Config
    @Values:
        GUI_ENDPOINT_NAME: "virtdb-gui"
        CONFIG_SERVICE_ADDRESS: "tcp://192.168.221.11:12345"
        DB_CONFIG_SERVICE: "greenplum-config"
        REQUEST_TIMEOUT: "15s"

module.exports = Config
