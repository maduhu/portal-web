<#-- @ftlvariable name="" type="org.gbif.portal.action.species.HomeAction" -->
<#import "/WEB-INF/macros/common.ftl" as common>
<html>
<head>
  <title>Species Search</title>
</head>

<body class="infobandless">

  <article class="search_home">
    <header></header>
    <div class="content">
      <h1>
          Search ${colSpecies!0} species
      </h1>
      <p>of the <a href="<@s.url value='/dataset/${nubDatasetKey}'/>">GBIF Backbone Taxonomy</a></p>

      <form action="<@s.url value='/species/search'/>" method="GET">
        <span class="input_text">
         <input id="q" type="text" value="" name="q" placeholder="Scientific or common name, descriptions..."/>
        </span>
        <button id="submitSearch" type="submit" class="search_button"><span>Search</span></button>
        <input id="checklist" name="dataset_key" type="hidden" value="${nubDatasetKey}"/>
      </form>

      <div class="example">  </div>

      <ul class="species">
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=359'/>" title="Mammals">Mammals</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=212'/>" title="Birds">Birds</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=358'/>" title="Reptiles">Reptiles</a></li>
        <#--
         see http://en.wikipedia.org/wiki/Fish#Taxonomy
         MISSING FROM THESE FISH FILTERS ARE THE FOLLOWING, WHICH ARE NOT IN COL:
          - Placodermi
        -->
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=119&highertaxon_key=120&highertaxon_key=121&highertaxon_key=204&highertaxon_key=238&highertaxon_key=239&highertaxon_key=4853178&highertaxon_key=3238258&highertaxon_key=4836892&highertaxon_key=4815623'/>" title="Fishes">Fishes</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=216'/>" title="Insects">Insects</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=797'/>" title="Butterflies">Butterflies</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=5'/>" title="Fungi">Fungi</a></li>
        <li><a href="<@s.url value='/species/search?q=&dataset_key=${nubDatasetKey}&highertaxon_key=7707728'/>" title="Vascular Plants">Vascular Plants</a></li>
      </ul>

    <#if nubSpecies gt 0>
      <div class="species-progress">
          <!-- this should always be the case when we have a real backbone -->
          <#assign progress = (100*colSpecies) / nubSpecies>
        <ul>
          <li class="confirmed" style="width:${progress}%">
            ${colSpecies}
          </li>
          <li class="unconfirmed" style="width:${100-progress}%">
            ${nubSpecies-colSpecies}
          </li>
        </ul>
        <ul style="width:${progress}%">
          <li class="confirmed-text" >
              Confirmed species in the <br/> <a href="<@s.url value='/dataset/${colKey}'/>">Catalogue of Life</a>
          </li>
          <li class="unconfirmed-text" style="width:${100-progress}%">
            Names under review
            <@common.popup message="There is currently no complete checklist of all known species.  Checklists published through GBIF are integrated into a backbone taxonomy, but these names require review before being considered a species.
            GBIF is working with other initiatives to review names and help to complete a global species list." title="Names under review"/>
            </a></span>
          </li>
        </ul>
      </div>
    </#if>
    </div>

    <footer></footer>
  </article>

</body>
</html>
