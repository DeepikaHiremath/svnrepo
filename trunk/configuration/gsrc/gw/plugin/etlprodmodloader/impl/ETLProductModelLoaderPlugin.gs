package gw.plugin.etlprodmodloader.impl

uses gw.api.database.Query
uses gw.api.productmodel.ClausePattern
uses gw.api.productmodel.ModifierPattern
uses gw.api.system.PCDependenciesGateway
uses gw.api.system.PCLoggerCategory
uses gw.plugin.etlprodmodloader.IETLProductModelLoaderPlugin
uses gw.plugin.etlprodmodloader.impl.factory.ETLClausePatternCreator
uses gw.plugin.etlprodmodloader.impl.factory.ETLModifierPatternCreator
uses gw.transaction.Transaction

/**
 * This plugin does the creation of the ETL Product Model entities which maps the publicIDs of clause
 * and clause terms to actual values. The current definitions and decoding of the product model
 * information in PolicyCenter currently resides in XML files does not currently exist at the database level.
 * This plugin performs the extraction of coverage data into meaningful business relevance that could be
 * utilized by downstream systems.
 */
@Export
class ETLProductModelLoaderPlugin implements IETLProductModelLoaderPlugin {
  override function loadProductModel() {
    PCLoggerCategory.ETL_PRODMODLOADER_PLUGIN.info("ETLProductModelLoaderPlugin: ETL product model tables - starting load...")
    deleteModel()
    loadModel()
    PCLoggerCategory.ETL_PRODMODLOADER_PLUGIN.info("ETLProductModelLoaderPlugin: ETL product model tables - load complete...")
  }

  /**
   * This methods deletes all of the ETL product model rows from the database
   */
  internal function deleteModel() {
    Transaction.runWithNewBundle(\bundle -> {
      var etlClausePatterns = Query.make(ETLClausePattern).select().toList()
      for (clausePattern in etlClausePatterns) {
        bundle.delete(clausePattern)
      }
      var etlModifierPatterns = Query.make(ETLModifierPattern).select().toList()
      for (modifierPattern in etlModifierPatterns) {
        bundle.delete(modifierPattern)
      }
    }, "su")
  }

  /**
   * This method loads the ETL product model entities into the database by calling
   * the appropriate ETL pattern creators
   */
  internal function loadModel() {
    Transaction.runWithNewBundle(\bundle -> {
      for (clausePattern in PCDependenciesGateway.getProductModel().getAllInstances(ClausePattern).toTypedArray()) {
        ETLClausePatternCreator.createETLClausePattern(clausePattern, bundle)
      }

      // Load all Modifier Patterns and associated Rate Factor Patterns
      for (modifierPattern in PCDependenciesGateway.getProductModel().getAllInstances(ModifierPattern).toTypedArray()) {
        ETLModifierPatternCreator.createETLModifierPattern(modifierPattern, bundle)
      }
    }, "su")
  }
}