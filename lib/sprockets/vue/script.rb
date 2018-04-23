require 'active_support/concern'
require "action_view"
module Sprockets::Vue
  class Script
    class << self
      include ActionView::Helpers::JavaScriptHelper

      SCRIPT_REGEX = Utils.node_regex('script')
      TEMPLATE_REGEX = Utils.node_regex('template')
      SCRIPT_COMPILES = {
        'coffee' => ->(s, input){
          CoffeeScript.compile(s, sourceMap: true, sourceFiles: [input[:source_path]], no_wrap: true)
        },
        'es6' => ->(s, input){
          Babel::Transpiler.transform(data, {}) #TODO
        },
        nil => ->(s,input){ { 'js' => s } }
      }
      def call(input)
        data = input[:data]
        name = input[:name]
        input[:cache].fetch([cache_key, input[:source_path], data]) do
          script = SCRIPT_REGEX.match(data)
          template = TEMPLATE_REGEX.match(data)
          output = []
          map = nil
          if script
            result = SCRIPT_COMPILES[script[:lang]].call(script[:content], input)
            
            map = result['sourceMap']

            output << "'object' != typeof VComponents && (this.VComponents = {});
              var module = { exports: null };
              #{result['js']}; VComponents['#{name}'] = module.exports;"
          end

          if template
            output << "VComponents['#{name.sub(/\.tpl$/, "")}'].template = '#{j template[:content]}';"
          end

          result = {
            data: "#{warp(output.join)}",
            map: map
          }

          preprocessor_result = run_preprocessors(script, input)
          if preprocessor_result
            result[:required]     = preprocessor_result[:required] if preprocessor_result[:required].any?
            result[:dependencies] = preprocessor_result[:dependencies] if preprocessor_result[:dependencies].any?
          end
          
          result
        end
      end

      def warp(s)
        "(function(){#{s}}).call(this);"
      end

      def cache_key
        [
          self.name,
          VERSION,
        ].freeze
      end

    protected
      #
      # Enable use of sprockets directives by running the script content through already registered preprocessors
      #
      def run_preprocessors(source, input)
        return unless source && source[:content] && input[:environment] && input[:environment].preprocessors["application/javascript"].try(:any?)
        input[:environment].preprocessors["application/javascript"][0].call(
          environment: input[:environment],
          data: source[:content],
          content_type: 'application/javascript',
          filename: input[:filename],
          metadata: {}
        )
      end
    end
  end
end
