defmodule MychatWeb.MyPageLive do
  use MychatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    topics = Topics.Agent.list
    Logger.info(topics: topics)
    {:ok, assign(socket, query: "", results: %{}, topics: topics)}
  end

  @impl true
  def handle_event("random-room", _params, socket) do
    random_slug = MnemonicSlugs.generate_slug(4)
    random_slug_path = "/" <> random_slug

    list = Topics.Agent.put(random_slug)

    # Logger.info(random_slug)

    {:noreply, push_redirect(socket, to: random_slug_path) }
  end

  @impl true
  def handle_event("opened-room", params, socket) do
    topic = "/" <> Map.get(params, "topic")
    Logger.info(topic: topic, params: params)
    {:noreply, push_redirect(socket, to: topic) }
  end
end
