defmodule Topics.Agent do
  @moduledoc false
  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # agent es el pid del Agent -> KV.Agent
  # Agent.get(agent, fn content -> Map.get(content, key) end)
  def get(key) do
    Agent.get(__MODULE__, &Enum.find(&1, fn e -> e == key end))
  end

  # fn map -> Map.put(map, key, value) end
  def put(key) do
    Agent.update(__MODULE__, &Enum.uniq([key | &1]))
  end

  def list() do
    Agent.get(__MODULE__, &(&1))
  end

  def delete(key) do
    Agent.update(__MODULE__, &(Enum.reject(&1, fn e -> e == key end)))
    {:ok, list()}
  end


end
