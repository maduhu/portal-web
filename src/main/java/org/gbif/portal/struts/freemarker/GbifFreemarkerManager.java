package org.gbif.portal.struts.freemarker;

import java.util.Locale;
import javax.servlet.ServletContext;

import freemarker.template.TemplateException;
import freemarker.template.TemplateExceptionHandler;
import org.apache.struts2.views.freemarker.FreemarkerManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class GbifFreemarkerManager extends FreemarkerManager {
  private static final Logger LOG = LoggerFactory.getLogger(GbifFreemarkerManager.class);

  @Override
  public void init(ServletContext servletContext) throws TemplateException {
    super.init(servletContext);
    LOG.info("Init custom GBIF Freemarker Manager");
    // custom ftl exception handling
    config.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
    // adding date rendering methods
    config.setSharedVariable("niceDate", new NiceDateTemplateMethodModel());
    // fixed locale, so we don't get dots as decimal separators or US "middle endian" dates.
    // chose UK, as (from the constants available) that gives unambiguous short dates like "12-Jan-2016".
    config.setLocale(Locale.UK);
  }

}
