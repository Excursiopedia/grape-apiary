module GrapeApiary
  class SampleGenerator
    attr_reader :resource, :root

    delegate :unique_params, to: :resource

    def initialize(resource)
      @resource = resource
      @root     = resource.key.singularize
    end

    def sample(id = false)
      hash = resource.unique_params.inject({}) do |result, param|
        parsed_name = param.name.scan(/\[([^\]]+)\]/).flatten
        name = parsed_name.pop || param.name

        node = parsed_name.inject(result) do |n, k|
          n[k] ||= begin
            parent_name = param.name.match(/(.+)\[.+\]/)[1]
            parent = resource.unique_params.find { |p| p.name == parent_name }
            parent.type == 'Array' ? [{}] : {}
          end

          n[k].is_a?(Array) ? n[k].first : n[k]
        end

        node[name] = param.example
        result
      end

      hash = hash.reverse_merge(id: Config.generate_id) if id
      hash = { root => hash } if Config.include_root
      hash
    end

    def request
      hash = sample
      pretty_json(hash) if hash.present?
    end

    def response(list = false)
      hash = sample(true)
      return if hash.blank?
      hash = [hash] if list
      pretty_json(hash)
    end

    private

    def pretty_json(hash)
      # format json spaces for blueprint markdown
      indent(JSON.pretty_generate(hash), 12, ' ')
    end

    def indent(string, count, char = ' ')
      string.gsub(/([^\n]*)(\n|$)/) do |match|
        last_iteration = ($1 == '' && $2 == '')
        line = ''
        line << (char * count) unless last_iteration
        line << $1
        line << $2
        line
      end
    end
  end
end
