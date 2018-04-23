<script lang="coffee">
#= require javascripts/js-plugin
module.exports = {

  methods:
    callPlugin: ->
      SuperFancyJavascriptPlugin.hello
      
}
</script>

<template>
  <div class="container">
    <p> {{ callPlugin }} </p>
  </div>
</template>

<style lang="scss">
</style>
