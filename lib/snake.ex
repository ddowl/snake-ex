defmodule SnakeEx do
  require Integer

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @behaviour Ratatouille.App
  @block "█"

  @up key(:arrow_up)
  @down key(:arrow_down)
  @left key(:arrow_left)
  @right key(:arrow_right)
  @arrows [@up, @down, @left, @right]

  def init(%{window: window}) do
    log_filename = __ENV__.file |> Path.join("../snake.log") |> Path.expand()
    log_file = File.open!(log_filename, [:write, :utf8])
    IO.puts(log_file, "in init!")

    grid_height = window.height - 2
    grid_width = window.width - 2

    %{
      pellet: rand_pos(grid_width, grid_height),
      snake: [rand_pos(grid_width, grid_height)],
      direction_curr: nil,
      direction_buf: nil,
      alive: true,
      height: grid_height,
      width: grid_width,
      log_file: log_file
    }
  end

  def update(model, msg) do
    case msg do
      {:event, %{key: key}} when key in @arrows ->
        %{model | direction_buf: next_direction(model.direction_curr, key_code_to_direction(key))}

      :tick ->
        new_model = %{model | direction_curr: model.direction_buf}
        move_snake(new_model)

      _ ->
        model
    end
  end

  def subscribe(_model) do
    Ratatouille.Runtime.Subscription.interval(50, :tick)
  end

  def render(%{snake: snake} = model) do
    view do
      panel(
        color: :green,
        padding: 0,
        height: :fill,
        title:
          "Snake! Grab the pellet, and avoid the walls! Score=#{length(snake)} (Press q to quit)"
      ) do
        render_grid(model)
      end
    end
  end

  def render_grid(%{alive: false}) do
    label(content: "Game Over")
  end

  def render_grid(%{alive: true} = model) do
    canvas(height: model.height, width: model.width) do
      pellet_cell(model.pellet)
      snake_cells(model.snake)
    end
  end

  defp rand_pos(width, height) do
    even_xs = 0..(width - 1) |> Enum.filter(&Integer.is_even(&1))
    even_ys = 0..(height - 1) |> Enum.filter(&Integer.is_even(&1))
    {Enum.random(even_xs), Enum.random(even_ys)}
  end

  defp pellet_cell(pos) do
    full_block(pos, :red)
  end

  defp snake_cells(snake) do
    Enum.map(snake, &full_block(&1, :green))
  end

  defp next_direction(:up, :down), do: :up
  defp next_direction(:down, :up), do: :down
  defp next_direction(:left, :right), do: :left
  defp next_direction(:right, :left), do: :right
  defp next_direction(_curr_direction, key_direction), do: key_direction

  defp key_code_to_direction(@up), do: :up
  defp key_code_to_direction(@down), do: :down
  defp key_code_to_direction(@left), do: :left
  defp key_code_to_direction(@right), do: :right

  defp move_snake(model) do
    [head | _tail] = model.snake
    next_head = next_pos(head, model.direction_curr)
    new_snake = [next_head | Enum.drop(model.snake, -1)]

    cond do
      out_of_bounds(model, next_head) || snake_overlapping(new_snake) ->
        %{model | alive: false}

      next_head == model.pellet ->
        next_pellet = rand_pos(model.width, model.height)
        %{model | pellet: next_pellet, snake: [next_head | model.snake]}

      true ->
        %{model | snake: new_snake}
    end
  end

  defp next_pos({x, y}, :up), do: {x, y - 1}
  defp next_pos({x, y}, :down), do: {x, y + 1}
  defp next_pos({x, y}, :left), do: {x - 2, y}
  defp next_pos({x, y}, :right), do: {x + 2, y}
  defp next_pos({x, y}, _), do: {x, y}

  defp out_of_bounds(model, {head_x, head_y}) do
    head_x < 0 || head_x >= model.width || head_y < 0 || head_y >= model.height
  end

  defp snake_overlapping([head | tail]) do
    Enum.any?(tail, &(&1 == head))
  end

  defp full_block({x, y}, color) do
    [
      canvas_cell(x: x, y: y, char: @block, color: color),
      canvas_cell(x: x + 1, y: y, char: @block, color: color)
    ]
  end
end
