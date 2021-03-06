# frozen_string_literal: true

class GitlabSchema < GraphQL::Schema
  # Took our current most complicated query in use, issues.graphql,
  # with a complexity of 19, and added a 20 point buffer to it.
  # These values will evolve over time.
  DEFAULT_MAX_COMPLEXITY   = 40
  AUTHENTICATED_COMPLEXITY = 50
  ADMIN_COMPLEXITY         = 60

  use BatchLoader::GraphQL
  use Gitlab::Graphql::Authorize
  use Gitlab::Graphql::Present
  use Gitlab::Graphql::Connections
  use Gitlab::Graphql::Tracing

  query_analyzer Gitlab::Graphql::QueryAnalyzers::LogQueryComplexity.analyzer

  query(Types::QueryType)

  default_max_page_size 100

  max_complexity DEFAULT_MAX_COMPLEXITY

  mutation(Types::MutationType)

  def self.execute(query_str = nil, **kwargs)
    kwargs[:max_complexity] ||= max_query_complexity(kwargs[:context])

    super(query_str, **kwargs)
  end

  def self.max_query_complexity(ctx)
    current_user = ctx&.fetch(:current_user, nil)

    if current_user&.admin
      ADMIN_COMPLEXITY
    elsif current_user
      AUTHENTICATED_COMPLEXITY
    else
      DEFAULT_MAX_COMPLEXITY
    end
  end
end
