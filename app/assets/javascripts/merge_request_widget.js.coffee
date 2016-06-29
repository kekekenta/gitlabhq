class @MergeRequestWidget
  # Initialize MergeRequestWidget behavior
  #
  #   checkEnable           - Boolean, whether to check automerge status
  #   mergeCheckUrl - String, URL to use to check automerge status
  #   ci_status_url        - String, URL to use to check CI status
  #

  constructor: (opts) ->
    $('#modal_merge_info').modal(show: false)
    @firstCICheck = true
    @readyForCICheck = false
    @cancel = false
    clearInterval @fetchBuildStatusInterval

    @opts = opts || $('.merge-request-widget-options').data()
    console.log @opts

    @getMergeStatus() if @opts.getMergeStatus

    @clearEventListeners()
    @addEventListeners()
    @getCIStatus(false)
    @pollCIStatus()
    notifyPermissions()

  clearEventListeners: ->
    $(document).off 'page:change.merge_request'

  cancelPolling: ->
    @cancel = true

  addEventListeners: ->
    allowedPages = ['show', 'commits', 'builds', 'changes']
    $(document).on 'page:change.merge_request', =>
      page = $('body').data('page').split(':').last()
      if allowedPages.indexOf(page) < 0
        clearInterval @fetchBuildStatusInterval
        @cancelPolling()
        @clearEventListeners()

  mergeInProgress: (deleteSourceBranch = false)->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) ->
        if data.state == "merged"
          urlSuffix = if deleteSourceBranch then '?delete_source=true' else ''

          window.location.href = window.location.pathname + urlSuffix
        else if data.merge_error
          $('.mr-widget-body').html("<h4>" + data.merge_error + "</h4>")
        else
          callback = => @mergeInProgress(deleteSourceBranch)
          setTimeout(callback, 2000)
      dataType: 'json'

  getMergeStatus: ->
    $.get @opts.mergeCheckUrl, (data) ->
      $('.mr-state-widget').replaceWith(data)

  ciLabelForStatus: (status) ->
    if status is 'success'
      'passed'
    else
      status

  pollCIStatus: ->
    @fetchBuildStatusInterval = setInterval ( =>
      return if not @readyForCICheck

      @getCIStatus(true)

      @readyForCICheck = false
    ), 10000

  getCIStatus: (showNotification) ->
    _this = @
    $('.ci-widget-fetching').show()

    $.getJSON @opts.ciStatusUrl, (data) =>
      return if @cancel
      @readyForCICheck = true

      if data.status is ''
        return

      if @firstCICheck || data.status isnt @opts.ciStatus and data.status?
        @opts.ciStatus = data.status
        @showCIStatus data.status
        if data.coverage
          @showCICoverage data.coverage

        # The first check should only update the UI, a notification
        # should only be displayed on status changes
        if showNotification and not @firstCICheck
          status = @ciLabelForStatus(data.status)

          if status is "preparing"
            title = @opts.ciTitle.preparing
            status = status.charAt(0).toUpperCase() + status.slice(1);
            message = @opts.ciMessage.preparing.replace('{{status}}', status)
          else
            title = @opts.ciTitle.normal
            message = @opts.ciMessage.normal.replace('{{status}}', status)

          title = title.replace('{{status}}', status)
          message = message.replace('{{sha}}', data.sha)
          message = message.replace('{{title}}', data.title)

          notify(
            title,
            message,
            @opts.gitlabIcon,
            ->
              @close()
              Turbolinks.visit _this.opts.buildsPath
          )
        @firstCICheck = false

  showCIStatus: (state) ->
    return if not state?
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success", "skipped", "not_found"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled", "not_found"
          @setMergeButtonClass('btn-danger')
        when "running"
          @setMergeButtonClass('btn-warning')
        when "success"
          @setMergeButtonClass('btn-create')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCICoverage: (coverage) ->
    text = 'Coverage ' + coverage + '%'
    $('.ci_widget:visible .ci-coverage').text(text)

  setMergeButtonClass: (css_class) ->
    $('.js-merge-button,.accept-action .dropdown-toggle')
      .removeClass('btn-danger btn-warning btn-create')
      .addClass(css_class)
