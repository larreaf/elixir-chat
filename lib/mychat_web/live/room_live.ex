defmodule MychatWeb.RoomLive do
  use MychatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = room_id

    username = MnemonicSlugs.generate_slug(2)

    if connected?(socket) do
      Topics.Agent.put(topic)
      MychatWeb.Endpoint.subscribe(topic)
      MychatWeb.Presence.track(self(), topic, username, %{})
    end

    {:ok,
      assign(
        socket,
        room_id: room_id,
        topic: topic,
        username: username,
        is_writing: [],
        user_list: [],
        message: "",
        messages: [],
        temporary_assigns: [messages: []]
      )}
  end

  @impl true
  def terminate(_reason, socket) do
    Logger.info("terminating!")
    if socket.assigns.user_list !== [] do
      {:ok, list} = Topics.Agent.delete(socket.assigns.topic)
      Logger.info(topics: list, this_topic: socket.assigns.topic)
      Logger.info("unsubscribing!")
      MychatWeb.Endpoint.unsubscribe(socket.assigns.topic)
      MychatWeb.Presence.untrack(self(), socket.assigns.topic, socket.assigns.username)
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username -> join_message(username) end)

    leaves_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username -> leaves_message(username) end)

    user_list =
      MychatWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()
    # Logger.info(user_list: user_list)

    {:noreply,
      assign(socket,
      messages: Enum.concat(join_messages, leaves_messages),
      user_list: user_list
      )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    # Logger.info("submit_message: #{message}")

    message = new_message(message, socket.assigns.username)

    MychatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    MychatWeb.Endpoint.broadcast_from(self(), socket.assigns.topic, "no-writing", socket.assigns.username)
    
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    # Logger.info("form_update:  #{message}")
    # Logger.info(message: message)
    if message !== "" do
      MychatWeb.Endpoint.broadcast_from(self(), socket.assigns.topic, "is-writing", socket.assigns.username)
    else
      MychatWeb.Endpoint.broadcast_from(self(), socket.assigns.topic, "no-writing", socket.assigns.username)
    end

    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message, topic: topic}, socket) do
    # Logger.info(payload: message)

    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "is-writing", payload: username, topic: topic}, socket) do
    Logger.info(payload: username)

    are_writing_users =
      [username | socket.assigns.is_writing]
      |> Enum.uniq

    {:noreply, assign(socket, is_writing: are_writing_users)}
  end

  @impl true
  def handle_info(%{event: "no-writing", payload: username, topic: topic}, socket) do
    Logger.info(payload: username)

    are_writing_users =
      socket.assigns.is_writing
      |> Enum.reject(&(&1 === username))

    {:noreply, assign(socket, is_writing: are_writing_users)}
  end

  # display

  def display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
      <p id="<%= uuid %>"> <%= content %> </p>
    """
  end

  def display_message(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>"> <strong><%= username %></strong>: <%= content %> </p>
    """
  end

  # privates
  defp new_message(content, username) do
    %{uuid: UUID.uuid4(), content: content, username: username}
  end

  defp new_system_message(content) do
    %{type: :system, uuid: UUID.uuid4(), content: content}
  end

  defp join_message(username) do
    new_system_message("#{username} joined the chat")
  end

  defp leaves_message(username) do
    new_system_message("#{username} leaved the chat")
  end

end
