package gw.plugin.rateflow

uses gw.api.startable.IStartablePlugin
uses gw.api.startable.StartablePluginCallbackHandler
uses gw.api.startable.StartablePluginState
uses gw.api.startup.PCPreloadActions
uses gw.api.system.PCDependenciesGateway

@Export
class RateBookPreloaderStartable implements IStartablePlugin {
  var _state: StartablePluginState as readonly State = Stopped

  override function start(pluginCallbackHandler: StartablePluginCallbackHandler, serverStarting: boolean) {
    if (serverStarting) {
      PCDependenciesGateway.RateBookCache.onStart(\-> {
        pluginCallbackHandler.log(RateBookPreloaderStartable.Type.DisplayName + ": rate book preload starting")
        PCPreloadActions.loadAllRateBooks()
        pluginCallbackHandler.log(RateBookPreloaderStartable.Type.DisplayName + ": rate book preload complete")
      })
    }
    _state = Started
  }

  override function stop(serverShuttingDown: boolean) {
    _state = Stopped
  }
}
