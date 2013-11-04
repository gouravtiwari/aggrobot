module Aggrobot
  class DefaultGroupsQueryPlanner < DefaultQueryPlanner

    def initialize(collection, group, default_groups, opts = {})
      raise_error 'Need to set group first' unless group
      super(collection, group)
      create_query_map(default_groups)
      @keep_empty = opts[:keep_empty]
    end


    def sub_query(group_name)
      @query_map[group_name]
    end

    def query_results(extra_cols = [])
      return empty_default_groups if collection_is_none?
      results = collect_query_results(extra_cols)
      results.reject! { |r| r[1] == 0 } unless @keep_empty
      results
    end

    private

    def collect_query_results(extra_cols)
      columns = ['', SqlAttributes.count] + extra_cols
      @query_map.collect do |group_name, query|
        sanitized_group_name = SqlAttributes.sanitize(group_name)
        columns[0] = sanitized_group_name
        results = query.group(sanitized_group_name).limit(1).pluck(*columns).first
        @query_map[group_name] = @query_map[group_name].none unless results
        results || [group_name, 0]
      end
    end

    def empty_default_groups
      @keep_empty ? @query_map.keys.collect { |k| [k, 0] } : []
    end

    def create_query_map(groups)
      @query_map = {}
      groups.each do |group|
        @query_map[group.to_s] = @collection.where(@group => group)
      end
    end

  end
end