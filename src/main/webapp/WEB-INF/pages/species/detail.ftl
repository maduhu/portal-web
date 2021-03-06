<#-- @ftlvariable name="" type="org.gbif.portal.action.species.DetailAction" -->
<#import "/WEB-INF/macros/common.ftl" as common>
<html>
<head>
  <title>${usage.scientificName} - Checklist View</title>
  <content tag="extra_scripts">
      <#--
        Set up the map if only we will use it.
        Maps are embedded as iframes, but we register event listeners to link through to the occurrence
        search based on the state of the widget.
      -->
      <#if nub && numOccurrences gt 0>
         <script type="text/javascript" src="${cfg.tileServerBaseUrl!}/map-events.js"></script>
         <script type="text/javascript">
             new GBIFMapListener().subscribe(function(id, searchUrl) {
               $("#geoOccurrenceSearch").attr("href", "<@s.url value='/occurrence/search'/>?" +  searchUrl);
             });
         </script>
      </#if>

      <#-- shadowbox to view large images -->
      <link rel="stylesheet" type="text/css" href="<@s.url value='/js/vendor/fancybox/jquery.fancybox.css?v=2.1.4'/>">
      <script type="text/javascript" src="<@s.url value='/js/vendor/fancybox/jquery.fancybox.js?v=2.1.4'/>"></script>
      <link rel="stylesheet" type="text/css" href="<@s.url value='/js/vendor/fancybox/helpers/jquery.fancybox-buttons.css?v=1.0.5'/>">
      <script type="text/javascript" src="<@s.url value='/js/vendor/fancybox/helpers/jquery.fancybox-buttons.js?v=1.0.5'/>"></script>

      <script type="text/javascript">
      // taxonomic tree state
      var $taxoffset= 0, loadedAllChildren=false;

      function renderUsages($ps, data){
        // hide loading wheel
        $ps.find(".loadingTaxa").fadeOut("slow");
        $(data.results).each(function() {
          var speciesLink = "<@s.url value='/species/'/>" + this.key;
          $htmlContent = '<li spid="' + this.key + '">';
          $htmlContent += '<span class="sciname"><a href="'+speciesLink+'">' + canonicalOrScientificName(this) + "</a></span>";
          $htmlContent += '<span class="rank">' + $i18nresources.getString("enum.rank." + (this.rank || "unknown")) + "</span>";
          if (this.numDescendants>0) {
            $htmlContent += '<span class="count">' + addCommas(this.numDescendants) + " descendants</span>";
          }
          $htmlContent += '</span></li>';
          $ps.find(".sp ul").append($htmlContent);
        })
      };

      // Function for loading and rendering children
      function loadChildren() {
        $ps=$("#taxonomicChildren");
        var $wsUrl = cfg.wsClb + "species/${id?c}/children?offset=" + $taxoffset + "&limit=25";
        // show loading wheel
        $ps.find(".loadingTaxa").show();
        //get the new list of children
        $.getJSON($wsUrl + '&callback=?', function(data) {
          renderUsages($ps, data);
          loadedAllChildren=data.endOfRecords;
        });
        $taxoffset += 25;
      }

      function loadDescription($descriptionKeys){
        var keys = $descriptionKeys.split(' ');
        // remove current description
        $("#description div.inner").empty();
        $.each(keys, function(index, k) {
          var key = $.trim(k);
          if (key) {
            var $wsUrl = cfg.wsClb + "description/" + key;
            $.getJSON($wsUrl + '?callback=?', function(data) {
              $htmlContent = "<h3>"+(data.type || "Description") +"</h3>";
              $htmlContent += "<p>"+data.description+"</p>";
              $htmlContent += '<p id="descriptionSrc'+index+'" class="note"><strong>Source</strong>: </p>';
              if (data.license) {
                  $htmlContent += '<p class="note"><strong>License</strong>: '+data.license+'</p>';
              }
              $("#description div.inner").append($htmlContent);
              $("#description div.inner").append("<br/><br/>");
              <#if nub>
                  $.getJSON(cfg.wsClb + "species/" + data.sourceTaxonKey+ "?callback=?", function(species) {
                      $.getJSON(cfg.wsReg + "dataset/" + species.datasetKey + "?callback=?", function(dataset) {
                          $("#descriptionSrc"+index).append('<a href="'+cfg.baseUrl+'/species/'+data.sourceTaxonKey+'">'+dataset.title+'</a>');
                      });
                  });
              </#if>
              if (data.source) {
                  $("#descriptionSrc"+index).append(data.source);
              <#if !nub>
              } else {
                  $("#descriptionSrc"+index).hide();
              </#if>
              }
            });
          }
        })
      }

      // show topics for a language
      function showLanguageTopics(lang){
          $("#description .topics").hide();
          $("#topics"+lang).show();
          $topicLi = $("#topics"+lang + " .topic:first");
          if ($topicLi.length > 0) {
            loadDescription($topicLi.attr("data-descriptionKeys"));
          };
          // adjust description height to ToC
          var tocHeight = $("#description div.right").height() - 5;
          if (tocHeight > 350) {
            $("#description div.inner").height(tocHeight);
          }
      }

      function initDescriptions(){
        <#if !descriptionToc.listLanguages().isEmpty()>
            $("#description .topic").click(function(event) {
              event.preventDefault();
              loadDescription( $(this).attr("data-descriptionKeys") );
            });
            $("#description .toclang").click(function(event) {
              event.preventDefault();
              showLanguageTopics($(this).attr("data-lang"));
            });
            // show first language ToC,
            // TODO: try to use in this order: user locale, english, first lang
            $showLang = "${descriptionToc.listLanguages()[0]}";
            showLanguageTopics($showLang);
        </#if>
      }

      $(function() {
        // taxonomic tree
        loadChildren();
        $("#taxonomicChildren .inner").scroll(function(){
          var triggerHeight = $("#taxonomicChildren .sp").height() - $(this).height() - 100;
          if (!loadedAllChildren && $("#taxonomicChildren .inner").scrollTop() > triggerHeight){
            loadChildren();
          }
        });

        // description TOC
        initDescriptions();

        // image slideshow
        $("#images").speciesSlideshow(${id?c}, '${usage.scientificName!"Untitled"}');
      });
    </script>
    <style type="text/css">
        #images .title {
          overflow: hidden;
          max-height: 85px;
        }
        #content #images .scrollable {
          height: 350px;
        }
    </style>
  </content>
<#-- RDFa -->
  <meta property="dwc:scientificName" content="${usage.scientificName!}"/>
  <meta property="dwc:kingdom" content="${usage.kingdom!}"/>
  <meta property="dwc:datasetID" content="${usage.datasetKey}"/>
  <meta property="dwc:datasetName" content="${(dataset.title)!"???"}"/>
  <meta rel="dc:isPartOf" href="<@s.url value='/dataset/${usage.datasetKey}'/>"/>
</head>
<body class="species">

<#assign tab="info"/>
<#include "/WEB-INF/pages/species/inc/infoband.ftl">

<#if !nub>
<#-- Warn that this is not a nub page -->
<@common.notice title="This is a particular view of ${usage.canonicalOrScientificName!}" id="checklistView" sessionBound=true>
  <p>This is <em>${usage.scientificName}</em> as seen by
      <#if constituent??><a href="<@s.url value='/dataset/${constituent.key}'/>">${constituent.title}</a>, a constituent of the </#if>
      <a href="<@s.url value='/dataset/${usage.datasetKey}'/>">${(dataset.title)!"???"}</a> checklist.
      <#if usage.nubKey?exists>
          <br/>Remember that you can also check the
          <a href="<@s.url value='/species/${usage.nubKey?c}'/>">GBIF view on ${usage.canonicalOrScientificName!}</a>
          by selecting the GBIF Backbone tab above.
      </#if>
  </p>
</@common.notice>
</#if>

<#-- Has this taxon been deleted? In other words, is the deleted timestamp not null? -->
<#if usage.deleted?has_content>
  <@common.notice title="Taxon has been removed">
      <p>You are viewing details for ${usage.canonicalOrScientificName!} which was removed on ${usage.deleted?date}.</p>
  </@common.notice>
</#if>

<@common.article id="overview" title="Overview">
<div class="left">

  <div class="col">
    <h3>Full Name</h3>
    <p><#if usage.isExtinct()!false>† </#if>${usage.scientificName}</p>
    <#if vernacularNames?has_content>
      <h3>Common names</h3>
      <ul>
        <#list vernacularNames as v>
          <li>${v.vernacularName}<#if v.language??> <span class="small">${v.language.getIso3LetterCode()}</span></#if></li>
          <#if v_has_next && v_index==2>
            <#break />
          </#if>
        </#list>
        <li class="more"><a href="<@s.url value='/species/${id?c}/vernaculars'/>">more</a></li>
      </ul>
    </#if>

    <#if (usage.synonyms?has_content)>
      <h3>Synonyms</h3>
      <ul class="no_bottom">
        <#list usage.synonyms as syn>
          <li><a href="<@s.url value='/species/${syn.key?c}'/>">${syn.scientificName}</a></li>
          <#-- only show 5 synonyms at max -->
          <#if syn_has_next && syn_index==4>
            <li class="more"><a href="<@s.url value='/species/${id?c}/synonyms'/>">more</a></li>
            <#break />
          </#if>
        </#list>
      </ul>
    </#if>

    <#if (usage.combinations?has_content)>
        <h3>Basionym of</h3>
        <ul class="no_bottom">
          <#list usage.combinations as comb>
            <li><a href="<@s.url value='/species/${comb.key?c}'/>">${comb.scientificName}</a></li>
            <#-- only show 5 combinations at max -->
            <#if comb_has_next && comb_index==4>
                <li class="more"><a href="<@s.url value='/species/${id?c}/combinations'/>">more</a></li>
              <#break />
            </#if>
          </#list>
        </ul>
    </#if>

  </div>

  <div class="col">
    <h3>Taxonomic status</h3>
    <p>
      <#if usage.synonym>
        <@s.text name="enum.taxstatus.${usage.taxonomicStatus!'SYNONYM'}"/>
          of <a href="<@s.url value='/species/${usage.acceptedKey?c}'/>">${usage.accepted!"???"}</a>
      <#elseif usage.rank??>
        <#if (usage.taxonomicStatus!"UNKNOWN") == 'UNKNOWN'>
          <@s.text name="enum.rank.${usage.rank}"/>
          of unknown status
        <#else>
          <@s.text name="enum.taxstatus.${usage.taxonomicStatus}"/> <@s.text name="enum.rank.${usage.rank}"/>
        </#if>
      <#else>
        <@s.text name="enum.taxstatus.${usage.taxonomicStatus!'UNKNOWN'}"/>
      </#if>
    </p>

    <#if usage.accordingTo?has_content>
      <h3>According to</h3>
      <p>${usage.accordingTo}</p>
    </#if>

    <#if usage.publishedIn?has_content>
      <h3>Published in</h3>
      <p>${usage.publishedIn}</p>
    </#if>

    <#if basionym?has_content && basionym.key != id>
      <h3>Basionym</h3>
      <p><a href="<@s.url value='/species/${basionym.key?c}'/>">${basionym.scientificName}</a></p>
    </#if>

    <#if usage.nomenclaturalStatus?has_content>
      <h3>Nomenclatural status</h3>
      <p><@common.renderNomStatusList usage.nomenclaturalStatus /></p>
    </#if>

    <#if (usage.livingPeriods?size>0)>
      <h3>Living period</h3>
      <p><#list usage.livingPeriods as p>${p?cap_first}<#if p_has_next>; </#if></#list></p>
    </#if>

    <#if habitats?has_content>
      <h3>Habitat</h3>
      <p>
        <#list habitats as h>${h?cap_first}<#if h_has_next>, </#if></#list>
      </p>
    </#if>

    <#if (usage.threatStatus?size>0)>
      <h3>Threat status</h3>
      <p><#list usage.threatStatus as t><#if t?has_content><@s.text name="enum.threatstatus.${t}"/><#if t_has_next>; </#if></#if></#list></p>
    </#if>

  </div>

  <#if usage.remarks?has_content>
    <div>
      <h3>Remarks</h3>
      <p>${usage.remarks}</p>
    </div>
  </#if>
</div>

<div class="right">
  <#if primeImage??>
    <div class="species_image">
      <a href="#images" class="images"><span><img src="../img/placeholder.png" data-load="${action.getImageCache(primeImage.identifier,'s')}" /></span></a>
    </div>
  </#if>

  <#if usage.nub>
      <dl class="identifier">
          <dt>GBIF ID</dt>
          <dd><a href="#" title="GBIF ID ${id?c}">${id?c}</a></dd>
        <#list usage.identifiers as i>
            <dt>${i.type}</dt>
            <dd><a href="${i.identifierLink!'#'}" title="${i.identifier}">${common.limit(i.identifier ,22)}</a></dd>
        </#list>
      </dl>

      <h3>Search links</h3>
      <ul>
        <#if usage.canonicalName??>
            <li><a target="_blank" href="http://eol.org/search/?q=${usage.canonicalOrScientificName}" title="Encyclopedia of Life">Encyclopedia of Life</a></li>
            <li><a target="_blank" href="http://www.catalogueoflife.org/col/search/all/key/${usage.canonicalName?replace(' ','+')}" title="Catalogue of Life">Catalogue of Life</a></li>
            <li><a target="_blank" href="http://www.biodiversitylibrary.org/name/${usage.canonicalName?replace(' ','_')}">Biodiversity Heritage Library</a></li>
        </#if>
      </ul>

  <#else>
    <#-- checklist view -->
      <dl class="identifier">
        <#if usage.taxonID??>
            <dt>Taxon ID</dt>
            <dd><a href="#" title="${usage.taxonID}">${usage.taxonID}</a></dd>
        </#if>
        <#list usage.identifiers as i>
            <dt>${i.type}</dt>
            <dd><a href="${i.identifierLink!'#'}" title="${i.identifier}">${common.limit(i.identifier ,22)}</a></dd>
        </#list>
      </dl>
      <#if usage.references??>
        <h3>Source</h3>
        <ul>
            <li><a target="_blank" href="${usage.references}">${dataset.alias!"Publisher record"}</a></li>
        </ul>
      </#if>
  </#if>

</div>
</@common.article>

<#-- Taxon maps are only calculated for the nub taxonomy -->

<#if nub && numOccurrences gt 0>
<a name="map"></a>
<article class="map">
  <header></header>


  <div class="content">
    <div class="map">
      <iframe id="map" name="map" src="${cfg.tileServerBaseUrl!}/index.html?type=TAXON&key=${usage.key?c}&resolution=${action.getMapResolution(numGeoreferencedOccurrences)}" allowfullscreen height="100%" width="100%" frameborder="0"/></iframe>
    </div>
    <div class="header">
      <div class="right"><h2>Georeferenced data</h2></div>
    </div>
	<div class="right">
      <div class="inner">
        <#if numGeoreferencedOccurrences gt 0>
          <h3>View records</h3>
          <p>
            <a href="<@s.url value='/occurrence/search?taxon_key=${usage.key?c}&HAS_COORDINATE=true&HAS_GEOSPATIAL_ISSUE=false'/>">All ${numGeoreferencedOccurrences} </a>
            |
            <a href="<@s.url value='/occurrence/search?taxon_key=${usage.key?c}&BOUNDING_BOX=90,-180,-90,180&HAS_GEOSPATIAL_ISSUE=false'/>" id='geoOccurrenceSearch'>In viewable area</a>
          </p>
        </#if>

        <#if usage.distributions?has_content>
          <h3>Distributions</h3>
          <p>
             Text based <a href="<@s.url value='/species/${id?c}/distributions'/>">distributions</a> present in some sources.
          </p>
        </#if>
      </div>
    </div>
  </div>
  <footer></footer>
</article>

</#if>
<#if usage.distributions?has_content>
  <#assign items=[] />
  <#list usage.distributions as d>
    <#if d.locationId?has_content || d.country?has_content || d.locality?has_content >
      <#assign item >
        <a href='<@s.url value='/species/${(d.sourceTaxonKey!usage.key)?c}#distribution'/>'>
        <@s.text name='enum.occurrencestatus.${d.status!"PRESENT"}'/>
        <#if d.establishmentMeans??> <@s.text name='enum.establishmentmeans.${d.establishmentMeans}'/></#if>
         in
        <#if d.country??>${d.country.title} ${d.locationId!}
          <@common.showIfDifferent d.country.title d.locality!></@common.showIfDifferent>
        <#else>
          ${d.locationId!} ${d.locality!}
        </#if>
        </a>
        <#if d.sourceTaxonKey?has_content || d.source?has_content>
          <span class="note">Source: ${d.source!("ChecklistBank "+d.sourceTaxonKey?c)}</span>
        </#if>
        <#if d.lifeStage?has_content || d.temporal?has_content || d.threatStatus?has_content || d.appendixCites?has_content>
        <span class="note">
          ${d.lifeStage!} ${d.temporal!}
            <#if d.threatStatus??><@s.text name="enum.threatstatus.${d.threatStatus}"/></#if>
            <#if d.appendixCites??>Cites ${d.appendixCites}</#if>
        </span>
        </#if>
      </#assign>
      <#assign items= items + [item] />
    </#if>
  </#list>
  <@common.article id="distribution" title="Distribution range">
    <div class="fullwidth">
      <@common.multiColList items=items columns=2 />
      <#if usage.distributions?size gte 10>
        <p><a href="<@s.url value='/species/${id?c}/distributions'/>">more distributions</a> ...</p>
      </#if>
    </div>
  </@common.article>
</#if>


<@common.article id="taxonomy" title="Subordinate taxa" titleRight="Classification" class="taxonomies">
    <div class="left">
      <#if usage.numDescendants gt 0>
        <div id="taxonomicChildren">
          <div class="loadingTaxa"><img src="../img/taxbrowser-loader.gif" alt=""></div>
          <div class="inner">
            <div class="sp">
              <ul>
              </ul>
            </div>
          </div>
        </div>
      <#else>
        <p>
           There are no subordinate taxa<#if usage.rank??> for this <@s.text name="enum.rank.${usage.rank}"/></#if>.<br/>
           You can explore the higher classification on the right.
        </p>
      </#if>
    </div>

    <div class="right">
      <dl>
      <#list rankEnum as r>
        <dt><@s.text name="enum.rank.${r}"/></dt>
        <dd>
          <#if usage.getHigherRankKey(r)??>
            <#if usage.getHigherRankKey(r) == usage.key>
              ${usage.canonicalOrScientificName}
            <#else>
              <a href="<@s.url value='/species/${usage.getHigherRankKey(r)?c}'/>">${usage.getHigherRank(r)}</a>
            </#if>
          <#elseif (usageMetrics.getNumByRank(r)!0) gt 0>
            <#-- TODO: check how to search for accepted only, removed status=ACCEPTED cause its too strict -->
            <a href="<@s.url value='/species/search?dataset_key=${usage.datasetKey}&rank=${r}&highertaxon_key=${usage.key?c}'/>">${usageMetrics.getNumByRank(r)}</a>
          <#else>
            ---
          </#if>
        </dd>
      </#list>
        <dt>&nbsp;</dt>
        <dd><a href="<@s.url value='/species/${id?c}/classification'/>">complete classification</a></dd>
      </dl>
    </div>
</@common.article>


<#if !descriptionToc.isEmpty()>
  <@common.article id="description" title='Description' class="">
    <div class="left">
      <div class="inner">
        <h3>Description</h3>
        <p></p>
      </div>
    </div>

    <div class="right">
      <h3>Table of Contents</h3>
      <#if descriptionToc.listLanguages().size() gt 1>
        <#list descriptionToc.listLanguages() as lang>
          <a class="toclang" href="#" data-lang="${lang}"><#if lang.getIso3LetterCode()?has_content>${lang.getIso3LetterCode()?upper_case}<#else>${lang.name()}</#if></a><#if lang_has_next>, </#if>
        </#list>
        <br/><br/>
      </#if>

      <#list descriptionToc.listLanguages() as lang>
        <ul id="topics${lang}" class="topics" class="no_bottom">
          <#assign topicMap = descriptionToc.listTopicEntries(lang)>
          <#list topicMap?keys as topic>
            <li><a class="topic" data-descriptionKeys="<#list topicMap.get(topic) as did>${did?c} </#list>">${topic?capitalize}</a></li>
          </#list>
        </ul>
      </#list>
    </div>
  </@common.article>
</#if>

<#if primeImage?exists>
  <@common.article id="images">
    <div class="species_images">
      <a class="controller previous" href="#" title="Previous image"></a>
      <a class="controller next" href="#" title="Next image"></a>
      <div class="scroller">
        <div class="photos"></div>
      </div>
    </div>

    <div class="right">
      <h2 class="title">...</h2>
      <div class="scrollable">

      </div>
    </div>
    <div class="counter">1 / 1</div>
  </@common.article>
</#if>

<#if usage.nubKey??>
  <@common.article id="appearsin" title="Appears in">
    <div class="fullwidth">
      <div class="col">
        <h3>Occurrence datasets</h3>
        <ul class="notes">
          <#assign counter=0 />
          <#list occurrenceDatasetCounts?keys as uuid>
            <#if datasets.get(uuid)??>
              <#assign counter=counter+1 />
              <#assign title=datasets.get(uuid).title! />
              <li>
                <a title="${title}" href="<@s.url value='/occurrence/search?taxon_key=${usage.nubKey?c}&dataset_key=${uuid}'/>">${common.limit(title, 55)}</a>
                <span class="note"> in ${occurrenceDatasetCounts.get(uuid)!0} occurrences</span>
              </li>
            </#if>
            <#if uuid_has_next && counter==6>
              <li class="more"><a href="<@s.url value='/species/${usage.nubKey?c}/datasets?type=OCCURRENCE'/>">${occurrenceDatasetCounts?size} more</a></li>
              <#break />
            </#if>
          </#list>
          <#if !occurrenceDatasetCounts?has_content>
              <li>None</li>
          </#if>
        </ul>
      </div>

      <div class="col">
        <h3>Checklists</h3>
        <ul class="notes">
          <#list related as rel>
            <#if datasets.get(rel.datasetKey)??>
              <#assign title=datasets.get(rel.datasetKey).title! />
              <li><a title="${title}" href="<@s.url value='/species/${rel.key?c}'/>">${common.limit(title, 55)}</a>
                <span class="note">as ${rel.scientificName}</span>
              </li>
            </#if>
            <#if rel_has_next && rel_index==5>
              <li class="more"><a href="<@s.url value='/species/${usage.nubKey?c}/datasets?type=CHECKLIST'/>">${related?size} more</a></li>
              <#break />
            </#if>
          </#list>
          <#if !related?has_content>
              <li>None</li>
          </#if>
        </ul>
      </div>
    </div>
  </@common.article>
</#if>

<#-- usage.typeSpecimens is misleading proeprty name, this is ONLY EVERY TYPE NAMES IN CLB -->
<#if usage.typeSpecimens?has_content>
  <#-- show CLB typification records -->
  <@common.article id="types" title="Typification">
    <div class="fullwidth">
      <ul class="notes">
      <#list usage.typeSpecimens as ts>
          <#-- require a sciname -->
          <#if ts.scientificName?has_content>
              <li>
                <a href="<@s.url value='/species/search?q=${ts.scientificName}'/>">${ts.scientificName}</a>
                <#if ts.typeDesignationType?has_content || ts.typeDesignatedBy?has_content>
                  <span class="note">${ts.typeDesignationType!}
                    <#if ts.typeDesignatedBy?has_content>
                        designated by ${ts.typeDesignatedBy!}
                    </#if>
                  </span>
                </#if>
                <#if ts.citation?has_content>
                    <span class="note">${ts.citation}</span>
                </#if>
                <#if ts.source?has_content>
                    <span class="note">Source: ${ts.source}</span>
                </#if>
              </li>
          </#if>
      </#list>
      </ul>
    </div>
  </@common.article>

<#elseif typeSpecimen?has_content>
  <#-- show type specimens from occurrences -->
  <@common.article id="types" title="Type Specimen">
    <div class="fullwidth">
      <ul class="notes">
      <#list typeSpecimen as occ>
              <li>
                  <#assign catnum = action.termValue(occ, 'catalogNumber')! />
                  <a href="<@s.url value='/occurrence/${occ.key?c}'/>">${occ.typeStatus} ${catnum!}</a>
                  <span class="note">
                    of <#if occ.typifiedName?has_content>${occ.typifiedName}<#else>${occ.scientificName!"?"}</#if>
                  </span>
              </li>
      </#list>
      </ul>
    </div>
  </@common.article>
</#if>


<#if (usage.referenceList?size>0)>
  <@common.article id="references" title="Bibliography">
    <div class="fullwidth">
      <#if usage.referenceList?has_content>
        <#list usage.referenceList as ref>
          <p>
            <#if ref.link?has_content><a href="${ref.link}">${ref.citation}</a><#else>${ref.citation}</#if>
            <#if ref.doi?has_content><br/>DOI:<a href="http://dx.doi.org/${ref.doi}">${ref.doi}</a></#if>
          </p>
          <#-- only show 8 references at max. If we have 8 (index=7) we know there are more to show -->
          <#if ref_has_next && ref_index==7>
            <p class="more"><a href="<@s.url value='/species/${id?c}/references'/>">more</a></p>
            <#break />
          </#if>
        </#list>
      </#if>
    </div>
  </@common.article>
</#if>

<#-- LEGAL -->
<#if !usage.deleted?has_content>
  <#if !nub && constituent??>
    <#assign prefix>${usage.scientificName}<#if usage.accordingTo?has_content> recognized by ${usage.accordingTo}</#if>, ${constituent.title} in </#assign>
  </#if>
  <@common.citationArticle rights=usage.rights!dataset.rights! dataset=dataset publisher=publisher prefix=prefix />
</#if>

<#if usage.issues?has_content>
  <@common.notice id="issues" title="Known issues">
      <p>There are known issues with this name usage:</p>
      <ul>
        <#list usage.issues as issue>
            <li><p><@s.text name="enum.usageissue.${issue.name()}"/></p></li>
        </#list>
      </ul>
  </@common.notice>
</#if>

<@common.notice title="Source information">
<p>
<#if nub>
  This backbone name usage is
  <#if usage.origin == "SOURCE">
    included because it was found in another checklist at the time the backbone was built.
    <#if nubSourceExists>
      <br/>View the <a class="source" data-baseurl="<@s.url value='/species/'/>" href="<@s.url value='/species/${usage.sourceTaxonKey?c}'/>">primary source usage</a>
      <#if constituent??>in <a href="<@s.url value='/dataset/${constituent.key}'/>">${constituent.title}</a></#if>.
    <#else>
      The primary source name usage <#if usage.sourceTaxonKey?has_content>(${usage.sourceTaxonKey?c})</#if> has since been removed from the portal.
    </#if>
  <#else>
    <@s.text name="enum.origin.${usage.origin}"/>.
  </#if>
<#else>
  <#if usage.origin! == "SOURCE">
      There may be more details available about this name usage in the
      <a href="<@s.url value='/species/${id?c}/verbatim'/>">verbatim version</a> of the record.
  <#else>
      This record has been created during indexing and did not explicitly exist in the source data as such.
      It was created as <@s.text name="enum.origin.${usage.origin}"/>.
  </#if>
</#if>
</p>
</@common.notice>



<@common.notice title="Record history">
<#if nub>
  <#if usage.lastInterpreted?has_content>
    <p>
      This record was last modified on ${usage.lastInterpreted?date?string.medium}.
      <#if usage.deleted??>It was removed on ${usage.deleted?date}.</#if>
    </p>
  </#if>

<#else>
  <#if usage.lastInterpreted?has_content>
    <p>
      This record was last modified in GBIF on ${usage.lastInterpreted?date?string.medium}.
      <#if usage.lastCrawled?has_content>
        The source was last visited by GBIF on ${usage.lastCrawled?date?string.medium}.
      </#if>
      <#if usage.modified??>
        It was last updated according to the publisher on ${usage.modified?date?string.medium}.
      </#if>
    </p>
  </#if>
    <p>A record will be modified by GBIF when either the source record has been changed by the publisher, or improvements in the GBIF processing warrant an update.</p>
</#if>
</@common.notice>
</body>
</html>
