DIAG = React.createClass(
    displayName: 'DIAG'
    render: ->
        style = (field) =>
            switch field.level
                when "ERROR"
                    "text-danger"
                when "INFO"
                    "text-info"
                when "SIMPLE_TRACE"
                    "text-muted"

        rows = []
        header = []
        header.push React.DOM.th null, 'Time'
        header.push React.DOM.th null, 'Component'
        header.push React.DOM.th null, 'Location'
        header.push React.DOM.th null, 'Message'
        if @props.data?
            @props.data.sort (a, b) ->
                b.time - a.time
            for item,index in @props.data
                children = []
                itemDate = new Date parseInt item.time
                console.log itemDate
                children.push React.DOM.td null, itemDate.toLocaleString()
                children.push React.DOM.td null, item.component
                children.push React.DOM.td null, item.file+':'+item.line+':'+item.function
                children.push React.DOM.td null, item.message
                rows.push React.DOM.tr {className: style(item), key: index}, children 
        head = React.DOM.thead null, React.DOM.tr null, header 
        body = React.DOM.tbody null, rows
        return React.DOM.table {className: "table"}, [head, body]
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
            console.log newValue
            display newValue
        , true
        return
