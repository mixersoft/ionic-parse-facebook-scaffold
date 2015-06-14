'use strict'

###*
# @ngdoc directive
# @name various
# @description various utility app directives
# @author Michael Lin, Snaphappi Inc.
#
###


angular.module('starter') 

.directive 'map', [ ()->
  return {
    restrict: 'E',
    scope: {
      onCreate: '&'
      latlon: '='
      # template: <map on-create="mapCreated(map)"" latlon="43.07493,-89.381388"></map>
    },
    link: ($scope, $element, $attr)->

      _map = null
      _initialize = ()->
        # 43.07493, -89.381388
        return if !$scope.latlon
        $scope.latlon = $scope.latlon.split(',') if _.isString $scope.latlon
        [lat,lon] = $scope.latlon
        # [lat,lon] = [43.07493, -89.381388]
        mapOptions = {
          center: new google.maps.LatLng(lat, lon),
          zoom: 16,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        }
        _map = new google.maps.Map($element[0], mapOptions)

        $scope.onCreate({map: _map})
        # // Stop the side bar from dragging when mousedown/tapdown on the map
        google.maps.event.addDomListener $element[0], 'mousedown', (e)->
          e.preventDefault();
          return false;

      $scope.$watch 'latlon', (newVal, oldVal)->
        return if !newVal 
        return _initialize() if !_map
        newVal = newVal.split(',') if _.isString newVal
        [lat,lon] = newVal
        _map.setCenter(new google.maps.LatLng(lat, lon))
        return 

      if document.readyState == "complete" 
        _initialize() 
      else
        google.maps.event.addDomListener(window, 'load', _initialize);
  }
]

.directive 'onImgLoad', ['$parse' , ($parse)->
  # add ion-animation.scss
  spinnerMarkup = '<i class="icon ion-load-c ion-spin light"></i>'
  _clearGif = 'img/clear.gif'
  _handleLoad = (ev, photo, index)->
    $elem = angular.element(ev.currentTarget)
    $elem.removeClass('loading')
    $elem.next().addClass('hide')
    onImgLoad = $elem.attr('on-img-load')
    fn = $parse(onImgLoad)
    scope = $elem.scope()
    scope.$apply ()->
      fn scope, {$event: ev}
      return
    return
  _handleError = (ev)->
    console.error "img.onerror, src="+ev.currentTarget.src


  return {
    restrict: 'A'
    link: (scope, $elem, attrs)->


      # NOTE: using collection-repeat="item in items"
      attrs.$observe 'ng-src', ()->
        $elem.addClass('loading')
        $elem.next().removeClass('hide')
        return

      $elem.on 'load', _handleLoad
      $elem.on 'error', _handleError
      scope.$on 'destroy', ()->
        $elem.off _handleLoad
        $elem.off _handleError
      $elem.after(spinnerMarkup)
      return
    }
  ]

  
.service 'PtrService', [
  '$timeout'
  '$ionicScrollDelegate' 
  ($timeout, $ionicScrollDelegate)-> 
    ###
     * Trigger the pull-to-refresh on a specific scroll view delegate handle.
     * @param {string} delegateHandle - The `delegate-handle` assigned to the `ion-content` in the view.
     * see: https://calendee.com/2015/04/25/trigger-pull-to-refresh-in-ionic-framework-apps/
    ###
    this.triggerPtr = (delegateHandle)->

      $timeout ()->

        scrollView = $ionicScrollDelegate.$getByHandle(delegateHandle).getScrollView();

        return if (!scrollView)

        scrollView.__publish(
          scrollView.__scrollLeft, -scrollView.__refreshHeight,
          scrollView.__zoomLevel, true)

        scrollView.refreshStartTime = Date.now()

        scrollView.__refreshActive = true
        scrollView.__refreshHidden = false
        scrollView.__refreshShow() if scrollView.__refreshShow
        scrollView.__refreshActivate() if scrollView.__refreshActivate
        scrollView.__refreshStart() if scrollView.__refreshStart

    return
        
]


.directive 'notify', ['notifyService'
  (notifyService)->
    return {
      restrict: 'A'
      scope: true
      templateUrl: 'views/template/notify.html'
      link: (scope, element, attrs)->
        scope.notify = notifyService

        if notifyService._cfg.debug
          window.debug.notify = notifyService        
        return
    }

]

