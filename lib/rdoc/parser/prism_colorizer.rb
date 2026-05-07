# frozen_string_literal: true

##
# Wrapper for Ripper lex states

class RDoc::Parser::PrismColorizer < Prism::Visitor
  Token = Struct.new(:start_offset, :end_offset, :type)

  attr_reader :tokens

  def self.tokens(parse_result)
    visitor = new(parse_result)
    parse_result.value.accept(visitor)
    visitor.tokens.sort_by(&:start_offset)
  end

  def initialize(parse_result)
    @tokens = []
    parse_result.comments.each do |comment|
      add_token(comment.location, :comment)
    end
  end

  def visit_call_node(node)
    add_token(node.message_loc, :ident) if node.name != :[]
    super
  end

  def visit_def_node(node)
    add_token(node.def_keyword_loc, :keyword)
    add_token(node.name_loc, :ident)
    add_token(node.end_keyword_loc, :keyword)
    super
  end

  def visit_block_local_variable_node(node)
    add_token(node.location, :ident)
  end
  alias visit_it_local_variable_read_node visit_block_local_variable_node
  alias visit_required_parameter_node visit_block_local_variable_node

  def visit_keyword_rest_parameter_node(node)
    add_token(node.name_loc, :ident)
    super
  end
  alias visit_block_parameter_node visit_keyword_rest_parameter_node
  alias visit_optional_parameter_node visit_keyword_rest_parameter_node
  alias visit_rest_parameter_node visit_keyword_rest_parameter_node#

  def visit_required_keyword_parameter_node(node)
    add_token(node.name_loc, :label)
    super
  end
  alias visit_optional_keyword_parameter_node visit_required_keyword_parameter_node

  # "foo"
  # ^^^^^
  def visit_string_node(node)
    if node.opening == "?"
      add_token(node.location, :char)
    elsif node.heredoc?
      add_token(node.opening_loc, :heredoc_delimiter)
      add_token(node.content_loc, :heredoc_content)
      add_token(node.closing_loc, :heredoc_delimiter)
    else
      add_token(node.location, :string)
    end
  end
  alias visit_x_string_node visit_string_node

  # "foo #{bar}"
  # ^^^^^^^^^^^^
  def visit_interpolated_string_node(node)
    if node.heredoc?
      add_token(node.opening_loc, :heredoc_delimiter)
      add_token(node.content_loc, :heredoc_content)
      add_token(node.closing_loc, :heredoc_delimiter)
    else
      add_token(node.location, :dstring)
    end
  end
  alias visit_interpolated_x_string_node visit_interpolated_string_node

  # :foo
  # ^^^^
  def visit_symbol_node(node)
    add_token(node.location, :symbol)
  end
  alias visit_interpolated_symbol_node visit_symbol_node

  # /foo/
  # ^^^^^
  def visit_regular_expression_node(node)
    add_token(node.location, :regexp)
  end
  alias visit_interpolated_regular_expression_node visit_regular_expression_node
  alias visit_match_last_line_node visit_regular_expression_node
  alias visit_interpolated_match_last_line_node visit_regular_expression_node

  # 1
  # ^
  def visit_integer_node(node)
    add_token(node.location, :int)
  end

  # 1.0
  # ^^^
  def visit_float_node(node)
    add_token(node.location, :float)
  end

  # 1r
  # ^^
  def visit_rational_node(node)
    add_token(node.location, :rational)
  end

  # 1i
  # ^^
  def visit_imaginary_node(node)
    add_token(node.location, :imaginary)
  end

  # $+
  # ^^
  def visit_back_reference_read_node(node)
    add_token(node.location, :backref)
  end
  alias visit_numbered_reference_read_node visit_back_reference_read_node

  # nil
  # ^^^
  def visit_nil_node(node)
    add_token(node.location, :keyword)
  end
  alias visit_true_node visit_nil_node
  alias visit_false_node visit_nil_node
  alias visit_redo_node visit_nil_node
  alias visit_retry_node visit_nil_node
  alias visit_self_node visit_nil_node
  alias visit_source_encoding_node visit_nil_node
  alias visit_source_file_node visit_nil_node
  alias visit_source_line_node visit_nil_node

  # @foo
  # ^^^^
  def visit_instance_variable_read_node(node)
    add_token(node.location, var_type(node.slice))
  end
  alias visit_local_variable_read_node visit_instance_variable_read_node
  alias visit_class_variable_read_node visit_instance_variable_read_node
  alias visit_global_variable_read_node visit_instance_variable_read_node
  alias visit_constant_read_node visit_instance_variable_read_node

  # @foo = 1
  # ^^^^^^^^
  def visit_instance_variable_write_node(node)
    add_token(node.name_loc, var_type(node.name_loc.slice))
    super
  end
  alias visit_local_variable_write_node visit_instance_variable_write_node
  alias visit_class_variable_write_node visit_instance_variable_write_node
  alias visit_global_variable_write_node visit_instance_variable_write_node
  alias visit_constant_write_node visit_instance_variable_write_node

  # @foo += bar
  # ^^^^^^^^^^^
  def visit_instance_variable_operator_write_node(node)
    add_token(node.name_loc, var_type(node.name_loc.slice))
    add_token(node.binary_operator_loc, :operator)
    super
  end
  alias visit_local_variable_operator_write_node visit_instance_variable_operator_write_node
  alias visit_class_variable_operator_write_node visit_instance_variable_operator_write_node
  alias visit_global_variable_operator_write_node visit_instance_variable_operator_write_node
  alias visit_constant_operator_write_node visit_instance_variable_operator_write_node

  # @foo &&= bar
  # ^^^^^^^^^^^^
  def visit_instance_variable_and_write_node(node)
    add_token(node.name_loc, var_type(node.name_loc.slice))
    add_token(node.operator_loc, :operator)
    super
  end
  alias visit_local_variable_and_write_node visit_instance_variable_and_write_node
  alias visit_class_variable_and_write_node visit_instance_variable_and_write_node
  alias visit_global_variable_and_write_node visit_instance_variable_and_write_node
  alias visit_constant_and_write_node visit_instance_variable_and_write_node

  # @foo ||= bar
  # ^^^^^^^^^^^^
  def visit_instance_variable_or_write_node(node)
    add_token(node.name_loc, var_type(node.name_loc.slice))
    add_token(node.operator_loc, :operator)
    super
  end
  alias visit_local_variable_or_write_node visit_instance_variable_or_write_node
  alias visit_class_variable_or_write_node visit_instance_variable_or_write_node
  alias visit_global_variable_or_write_node visit_instance_variable_or_write_node
  alias visit_constant_or_write_node visit_instance_variable_or_write_node

  # @foo, = bar
  # ^^^^
  def visit_instance_variable_target_node(node)
    add_token(node.location, var_type(node.slice))
  end
  alias visit_local_variable_target_node visit_instance_variable_target_node
  alias visit_class_variable_target_node visit_instance_variable_target_node
  alias visit_global_variable_target_node visit_instance_variable_target_node
  alias visit_constant_target_node visit_instance_variable_target_node

  # Foo::Bar
  # ^^^^^^^^
  def visit_constant_path_node(node)
    add_token(node.delimiter_loc, :operator)
    add_token(node.name_loc, :const)
    super
  end
  alias visit_constant_path_target_node visit_constant_path_node

  # Foo::Bar += 1
  # ^^^^^^^^^^^^^
  def visit_constant_path_operator_write_node(node)
    add_token(node.binary_operator_loc, :operator)
    super
  end

  # Foo::Bar &&= baz
  # ^^^^^^^^^^^^^^^^
  def visit_constant_path_and_write_node(node)
    add_token(node.operator_loc, :operator)
    super
  end
  alias visit_constant_path_or_write_node visit_constant_path_and_write_node

  # -> {}
  def visit_lambda_node(node)
    add_token(node.operator_loc, :operator)
    super
  end

  private

  def var_type(value)
    if value.start_with?("@@")
      :cvar
    elsif value.start_with?("@")
      :ivar
    elsif value.start_with?("$")
      :gvar
    elsif value.match?(/^[[:upper:]]\w*$/)
      :const
    else
      :ident
    end
  end

  def add_token(location, type)
    return unless location

    @tokens << Token.new(
      start_offset: location.start_offset,
      end_offset: location.end_offset,
      type: type,
    )
  end
end
