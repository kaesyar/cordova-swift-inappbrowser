/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

(function () {
  var exec = require('cordova/exec');
  var channel = require('cordova/channel');
  var modulemapper = require('cordova/modulemapper');
  var urlutil = require('cordova/urlutil');

  function InAppBrowser () {
    this.channels = {
      beforeload: channel.create('beforeload'),
      loadstart: channel.create('loadstart'),
      loadinit: channel.create('loadinit'),
      loadstop: channel.create('loadstop'),
      loaderror: channel.create('loaderror'),
      exit: channel.create('exit'),
      hide: channel.create('hide'),
      menu: channel.create('menu'),
      click: channel.create('click'),
      blank: channel.create('blank'),
      icon: channel.create('icon'),
      customscheme: channel.create('customscheme'),
      message: channel.create('message')
    };
    this.tabId = null;
  }

  InAppBrowser.prototype = {
    _eventHandler: function (event) {
      if (event && event.type in this.channels) {
        if (event.type === 'beforeload') {
          this.channels[event.type].fire(event, (...args) => this._loadAfterBeforeload(...args));
        } else {
          this.channels[event.type].fire(event);
        }
      }
    },
    _tabIdArgs: function () { return this.tabId ? [this.tabId] : []; },
    _loadAfterBeforeload: function (strUrl) {
      strUrl = urlutil.makeAbsolute(strUrl);
      exec(null, null, 'InAppBrowser', 'loadAfterBeforeload', [strUrl, ...this._tabIdArgs()]);
    },
    close: function () {
      exec(null, null, 'InAppBrowser', 'close', [...this._tabIdArgs()]);
    },
    navigate: function (url) {
      exec(null, null, 'InAppBrowser', 'navigate', [url, ...this._tabIdArgs()]);
    },
    reload: function () {
      exec(null, null, 'InAppBrowser', 'reload', [...this._tabIdArgs()]);
    },
    stop: function () {
      exec(null, null, 'InAppBrowser', 'stop', [...this._tabIdArgs()]);
    },
    show: function () {
      exec(null, null, 'InAppBrowser', 'show', [...this._tabIdArgs()]);
    },
    hide: function () {
      exec(null, null, 'InAppBrowser', 'hide', [...this._tabIdArgs()]);
    },
    screenshot: function (cb, scale, heightAspect) {
      exec(cb, null, 'InAppBrowser', 'screenshot', [...this._tabIdArgs(), scale, heightAspect]);
    },
    addEventListener: function (eventname, f) {
      if (eventname in this.channels) {
        this.channels[eventname].subscribe(f);
      }
    },
    removeEventListener: function (eventname, f) {
      if (eventname in this.channels) {
        this.channels[eventname].unsubscribe(f);
      }
    },
    executeScript: function (injectDetails, cb) {
      if (injectDetails.code) {
        exec(cb, null, 'InAppBrowser', 'injectScriptCode', [injectDetails.code, !!cb, ...this._tabIdArgs()]);
      } else if (injectDetails.file) {
        exec(cb, null, 'InAppBrowser', 'injectScriptFile', [injectDetails.file, !!cb, ...this._tabIdArgs()]);
      } else {
        throw new Error('executeScript requires exactly one of code or file to be specified');
      }
    },

    insertCSS: function (injectDetails, cb) {
      if (injectDetails.code) {
        exec(cb, null, 'InAppBrowser', 'injectStyleCode', [injectDetails.code, !!cb, ...this._tabIdArgs()]);
      } else if (injectDetails.file) {
        exec(cb, null, 'InAppBrowser', 'injectStyleFile', [injectDetails.file, !!cb, ...this._tabIdArgs()]);
      } else {
        throw new Error('insertCSS requires exactly one of code or file to be specified');
      }
    }
  };

  module.exports = function (strUrl, strWindowName, strWindowFeatures, callbacks) {
    // Don't catch calls that write to existing frames (e.g. named iframes).
    if (window.frames && window.frames[strWindowName]) {
      var origOpenFunc = modulemapper.getOriginalSymbol(window, 'open');
      return origOpenFunc.apply(window, arguments);
    }

    strUrl = urlutil.makeAbsolute(strUrl);
    var iab = new InAppBrowser();

    callbacks = callbacks || {};
    for (var callbackName in callbacks) {
      iab.addEventListener(callbackName, callbacks[callbackName]);
    }

    var cb = function (eventname) {
      iab._eventHandler(eventname);
    };

    strWindowFeatures = strWindowFeatures || '';
    if (strWindowFeatures.includes("multitab=yes")) {
      iab.tabId = ""+Math.random();
      console.log("url", strUrl, "tab", iab.tabId);
    }

    exec(cb, cb, 'InAppBrowser', 'open', [strUrl, strWindowName, strWindowFeatures, ...iab._tabIdArgs()]);
    return iab;
  };
})();
