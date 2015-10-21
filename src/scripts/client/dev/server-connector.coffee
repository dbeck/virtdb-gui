app = require './virtdb-app.js'
module.exports = app.factory 'ServerConnector', ['$http', '$timeout', 'ErrorService', '$q', ($http, $timeout, ErrorService, $q) ->
    new class ServerConnector

        constructor: () ->
            @address = ""
            @pendingRequestIds = {}

        getFeatures: (onSuccess) ->
            return { Security: true }

        getSettings: (onSuccess) ->
            $http.get @address + "/api/settings"
            .success(onSuccess)
            .error (response, status) ->
                ErrorService.errorHappened status, "Failed to get configuration. (#{response})"

        getCertificates: (onSuccess) ->
            $http.get @address + "/api/certificate"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get list of certificates. (#{response})"

        getMonitoring: (onSuccess) ->
            $http.get @address + "/api/monitoring"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get monitoring information. (#{response})"

        approveCertificate: (authCode, component, onSuccess) ->
            data =
                authCode: authCode
            $http.put @address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}", data
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to approve certificate of #{component.ComponentName}. (#{response})"

        removeCertificate: (component, onSuccess) ->
            $http.delete(@address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}/#{encodeURIComponent(component.PublicKey)}")
                .success(onSuccess)
                .error (response, status) =>
                    ErrorService.errorHappened status, "Failed to remove certificate of #{component.ComponentName}. (#{response})"

        getEndpoints: (onSuccess, onError) =>
            $http.get(@address + "/api/endpoints").success(onSuccess)
            .error(
                (response, status) =>
                    ErrorService.errorHappened status, "Failed to get component list. (#{response})"
            )

        getDataProviders: (onSuccess) =>
            onSuccess ["random", "oracle", "sap", "sap-cache", "oracle-cache", "googlesheet-provider", "some-very-long-long-name-provider"]

        getAuthenticationMethods: (onSuccess) =>
            $http.get(@address + "/api/authmethods").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get authentication methods. (#{response})"
                onSuccess []
            )

        getCurrentUser: (onSuccess) =>
            $timeout =>
                onSuccess
                    name: "admin"
                    password: null
                    tableTokens: {}
                    sourceSystemTokens: {}
                    token: "1438841921-20-LT"
            , 100

        getUserList: (onSuccess) =>
            $http.get(@address + "/api/user/list").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get user list. (#{response})"
                onSuccess []
            )

        deleteUser: (data, done) =>
            $http.delete(@address + "/api/user/" + data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to delete user #{data.name}. (#{response})"
            )

        updateUser: (data, done) =>
            $http.put(@address + "/api/user/" + data.name, data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to update user information of #{data.name}. (#{response})"
            )

        createUser: (data, done) =>
            $http.post(@address + "/api/user", data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to create user #{data.name}. (#{response})"
            )

        login: (username, password, done) =>
            data =
                username: username
                password: password
            $http.post(@address + "/login", data).success( -> done?())
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to loging user #{data.username}"
            )

        getTableList: (data, onSuccess, onError) =>
            $timeout =>
                onSuccess
                    from: 0
                    to: 49
                    count: 57
                    results: ["OOGMPP", "UZISIF", "MJBDXF", "KRBNUE", "RWRKOY", "MHYRPE", "YVXNXL", "TDJBLH", "ZEWQBX", "SPCIIS", "PCXNGV", "FLAWTO", "QGTHBQ", "YUQDQN", "UNQUJX", "ANCKZJ", "VBKHAX", "DPKZMA", "YWJUOQ", "CNFPOS", "EIUBRM", "HOLEJB", "EQXFPR", "THTKEU", "IOONEL", "CIHHCF", "ZNGFEZ", "UAOZHY", "GYKYCS", "TJGJSJ", "FSTMUY", "EWRZNS", "VGDZPZ", "JGACMJ", "IYJTEL", "HNIMIY", "KQQIBR", "IUNZVZ", "XVPNMZ", "BOJVKW", "PBWVKQ", "TCYFBF", "HKKOYZ", "JQSHJT", "PFAEAE", "WZYBSE", "SQCNSY", "HMAODN", "BXYBJR", "TRWAQB"]
                id: 851507
            , 100
            return 851507

        getMetaData: (data, onSuccess) =>
            $timeout =>
                onSuccess
                    Name: data.table
                    Comments: []
                    Properties: []
                    Fields: [
                        {
                            Name: "XGOCHL"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "PEJYGU"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "WABCYH"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "FIFAHZ"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "KMUIHZ"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "DQXJIA"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "JPAVJR"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "DYDGPW"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                        {
                            Name: "UDOJKA"
                            Desc:
                                Type: "STRING"
                            Comments: []
                            Properties: {}
                        }
                    ]
                    id: 614976
                , 100
            return 614976

        getData: (data, onSuccess) =>
            $timeout =>
                onSuccess [
                        ["GVOFCJ","HPKGOW","QJNIJL","ZOGCLF","FYMQUU","MEKPFO","DHQAYA","XBKBBD","HGDPTU"]
                        ["PUQOKS","SAWAIK","TWWWPC","DKQJXN","FMBFQI","XDCNWN","SVAPNT","BNBGLL","UQZHMS"]
                        ["XLWVTO","PGYFCB","NPDVOJ","QFIFWN","NKZMZP","ZXZQAV","TDTPQG","RZXPVD","CXCMKO"]
                        ["DEYWVO","HEFGRE","WZVQRO","SIBIIR","PEKRIT","TEFBUR","XVXCXH","XRGINY","PORGNN"]
                        ["SOTAOR","SVZCJS","EMWSSS","EDWSLQ","KYUVBB","HOWIOR","FMGTTO","NAQDIF","TTHKTC"]
                        ["SQDWMQ","RHUZEO","DSHEOU","KZOQOU","NENQGH","ZCNDSK","YHGCFY","CISJYD","VZDNJP"]
                        ["TJWOBW","JDALGW","CLPPKX","HQYAAM","KPCKLI","BZEEOR","AMIDJR","QGOMTU","XPJNCM"]
                        ["RAUKTK","OGRTPK","GZXMHJ","CJMAXR","XWBDPU","XNEWSK","NNVOEO","JILMQJ","QIOISF"]
                        ["AWMTRB","LSDVEO","RPAAZK","XWHRXD","NBUHTM","VCIQZQ","TTPMGY","KGUGBP","TZSLOT"]
                        ["TEHHKD","XELGYY","AUDKIR","IFKVCA","IWNWAP","HCUOGI","KCVODZ","XBYAOI","PQZOFZ"]
                        ["DPVVVC","RGFSWQ","LXIWEH","QTKSXS","ZDOGWR","LVPFMI","KLDCYI","AWGJPV","AGETCY"]
                        ["ORQTOG","FLBYFS","WDOSYI","XBGBNS","RRKWUI","CAULCJ","LNJEML","LOXZHV","QIQDBC"]
                        ["SWDOIP","XPGEVT","OUUFDD","DBNMXT","LOZGOQ","VASXWG","ZUOOBD","HHCKJK","ZVCEGP"]
                        ["XOGXND","VEMNHU","DCCQAI","BPTXFP","JQLHDL","OFLGAV","MNTXGL","IXNWCS","QTBAMN"]
                        ["CLUEBG","ASUPBT","IXNAOE","TLNGGQ","XGULVV","MTIJGY","FEPIBC","NFCDHI","YSXOKE"]
                        ["NUVLZZ","ZHSUQM","NJYKSB","EKSOQD","CLFMVA","MBITMD","XZQQPA","SPLURF","RXCSFM"]
                        ["NPCQLN","ZNHPZN","WECXDA","FAZLSN","GBRDRF","XQPNRJ","FRBTEX","OVCOQV","XSDUAI"]
                        ["IQZDLP","BKIGAQ","TKWQYJ","KQTHRN","GCERVR","MKXGXD","RLXPZH","WIBQLE","UZRIOG"]
                        ["OQCXYG","TQRIWH","HHPMKU","SLISVD","YUIGHI","CEAVCH","VOGWDZ","MABOIS","HMMOIK"]
                        ["MPMXUD","QQWVBB","LCIAUP","BWKMCZ","DKOUNX","HLNDOA","NZRRBJ","IMNAPL","WJJRAA"]
                    ]
            , 100
            return 233063

        getConfig: (data, onSuccess) =>
            $http.get @address + '/api/get_config/' + data.selectedComponent
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get configuration of component: #{data.selectedComponent} (#{response})"

        getCredential: (data, onSuccess) =>
            $http.get @address + '/api/get_credential/' + data.selectedComponent
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get credential template of component: #{data.selectedComponent} (#{response})"

        setCredential: (data, onSuccess) =>
            $http.post @address + '/api/set_credential/' + data.selectedComponent, data.credentials
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to set credential: #{data.selectedComponent} (#{response})"

        setConfig: (data, onSuccess, onError) =>
            $http.post @address + '/api/set_config/' + data.selectedComponent, data.componentConfig
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to set configuration of component: #{data.selectedComponent}  (#{response})"
                    onError(response, status)

        sendDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/add", data)
            .success(onSuccess)
            .error( (response, status) =>
                    ErrorService.errorHappened status, "Failed to #{data.action} table: #{data.table} (#{response})"
            )

        getDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/get", data)
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to retreive list of added tables from host database for: #{data.provider} (#{response})"
                onSuccess []
            )

        getLogs: (data, onDiagMessage) =>
            $http.post(@address + "/api/get_diag/", data)
            .success(onDiagMessage)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get log messages. (#{response})"
                onDiagMessage []
            )

        generateRequestId = () =>
            return Math.floor(Math.random() * 1000000) + 1

        cancelRequest: (id) =>
            canceler = @pendingRequestIds[id]
            if canceler?
                canceler.resolve "Request outdated"
                delete @pendingRequestIds[id]

        createCanceler: (id) =>
            canceller = $q.defer()
            @pendingRequestIds[id] = canceller
            return canceller.promise

]
