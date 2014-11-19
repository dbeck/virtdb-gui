class Config
    @Values:
        GUI_ENDPOINT_NAME: "virtdb-gui"
        DB_CONFIG_SERVICE: "greenplum-config"
        REQUEST_TIMEOUT: "15s"
        CACHE_TTL: "10m"
        CACHE_CHECK_PERIOD: "1m"

module.exports = Config
