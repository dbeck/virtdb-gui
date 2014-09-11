class MetaDataCache
    cache: {}

    constructor: () ->

    putTable: (table) =>
        @cache[table.Name] = table
        return

    getTable: (tableName) =>
        return @cache[tableName]

    set: (tables) =>
        for table in tables
            @putTable(table)

    get: () =>
        return @cache

    reset: () =>
        @cache = {}

module.exports = MetaDataCache
