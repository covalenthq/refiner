alias Porcelain.Result

defmodule Rudder do
  # block-result: block-specimen.json block-result.json
  #   ./evm block-specimen-X.json block-result-X.json

  # {
  #   "input": "block-specimen.json"
  #   "rules": "./evm block-specimen.json"
  #   "output": "block-result.json"
  # }

  def get_json(filename) do
    with {:ok, body} <- File.read(filename) do
      Poison.decode(body)
    end
  end

  def load_rules(filename) do
    # load the rules from json file (?) or makefile syntax
    # rules are written in json for now
    rules = get_json(filename)
    elem(rules, 1)
  end

  def load_input(rules) do
    Map.get(rules, "input")
  end

  def load_output_name(rules) do
    Map.get(rules, "output")
  end

  def load_build_rule(rules) do
    Map.get(rules, "rules")
  end

  def call_rule(build_rule) do
    # todo: use one of the Porcelain functions that uses message passing instead
    Porcelain.shell(build_rule)
  end

  def apply_rules(rules_filename) do
    # "meat" of this thing

    rules = load_rules(rules_filename)

    input = load_input(rules)

    build_rule = load_build_rule(rules)

    result = call_rule(build_rule)

    # output = load_output_name(rules_filename)

    # write_output(output, result)
  end

  def write_output(result) do
    # write a file
  end
end
