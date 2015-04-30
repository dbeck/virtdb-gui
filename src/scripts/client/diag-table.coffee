MAX_LENGTH = 100

DiagTable = React.createClass(
    displayName: 'DiagTable'
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
        header.push React.DOM.th { key: 'headtime' }, 'Time'
        header.push React.DOM.th { key: 'headcomponent' }, 'Component'
        header.push React.DOM.th { key: 'headlocation' }, 'Location'
        header.push React.DOM.th { key: 'headmessage' }, 'Message'
        if @props.data?
            console.log "Collection size: ", @props.data.length
            for item,index in @props.data
                children = []
                itemDate = new Date parseInt item.time
                children.push React.DOM.td { key: index + 'time' }, itemDate.toLocaleString()
                children.push React.DOM.td { key: index + 'component' }, item.component
                children.push React.DOM.td { key: index + 'location' }, item.function + ' @ ' + item.file + ':' + item.line
                children.push React.DOM.td { key: index + 'message' }, item.message.substring 0, MAX_LENGTH
                rows.push React.DOM.tr {className: style(item), key: index}, children
        head = React.DOM.thead { key: 'head' }, React.DOM.tr null, header
        body = React.DOM.tbody { key: 'body' }, rows
        return React.DOM.table {className: "table table-condensed table-striped diag-item"}, [head, body]
)

diagTableDirective = ->
    restrict: 'E'
    scope:
        data: "="
    link: (scope, el, attrs) ->
        display = (data) =>
            React.render(
                React.createElement DiagTable,
                    data: data
            , el[0])
        scope.$watch ->
            return scope.data
        , (newValue, oldValue) ->
            display newValue
        , true
        return

module.exports = diagTableDirective
