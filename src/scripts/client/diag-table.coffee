DIAG = React.createClass(
    displayName: 'DIAG'
    render: ->
        style = (field) =>
            ret = "diag-item"
            switch field.level
                when "ERROR"
                    ret += " text-danger"
                when "INFO"
                    ret += " text-info"
                when "SIMPLE_TRACE"
                    ret += " text-muted"

        rows = []
        header = []
        header.push React.DOM.th null, 'Time'
        header.push React.DOM.th null, 'Component'
        header.push React.DOM.th null, 'Location'
        header.push React.DOM.th null, 'Message'
        if @props.data?
            console.log "Collection size: ", @props.data.length
            for item,index in @props.data
                children = []
                itemDate = new Date parseInt item.time
                children.push React.DOM.td null, itemDate.toLocaleString()
                children.push React.DOM.td null, item.component
                children.push React.DOM.td null, item.function + ' @ ' + item.file + ':' + item.line
                children.push React.DOM.td null, item.message
                rows.push React.DOM.tr {className: style(item), key: index}, children 
        head = React.DOM.thead null, React.DOM.tr null, header 
        body = React.DOM.tbody null, rows
        return React.DOM.table {className: "table table-condensed table-striped diag-item"}, [head, body]
)

diagTableDirective = -> 
    restrict: 'E'
    scope:
        data: "="
    link: (scope, el, attrs) ->
        display = (data) =>
            React.render DIAG(data: data), el[0]
        scope.$watch ->
            return scope.data
        , (newValue, oldValue) ->
            display newValue
        , true
        return
