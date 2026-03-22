using Microsoft.AspNetCore.Mvc;
using QuizGame.Application.DTOs;
using QuizGame.Application.Interfaces;

namespace QuizGame.Presentation.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class GameRoomController : ControllerBase
{
    private readonly IGameRoomService _roomService;
    private readonly IGameManager _gameManager;

    public GameRoomController(IGameRoomService roomService, IGameManager gameManager)
    {
        _roomService = roomService;
        _gameManager = gameManager;
    }

    /// <summary>Create a new game room. Returns the room with its 6-char code.</summary>
    [HttpPost("create")]
    [ProducesResponseType(typeof(GameRoomDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateRoom([FromBody] CreateRoomRequest request)
    {
        var room = await _roomService.CreateRoomAsync(
            request.HostUserId, request.MaxPlayers, request.TotalQuestions);

        return CreatedAtAction(nameof(GetRoom), new { code = room.RoomCode }, room);
    }

    /// <summary>Get room details by room code</summary>
    [HttpGet("{code}")]
    [ProducesResponseType(typeof(GameRoomDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRoom(string code)
    {
        var room = await _roomService.GetRoomByCodeAsync(code);
        return room == null ? NotFound() : Ok(room);
    }

    /// <summary>Join a room via room code (REST pre-join; SignalR handles live join)</summary>
    [HttpPost("join")]
    [ProducesResponseType(typeof(PlayerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> JoinRoom([FromBody] JoinRoomRequest request)
    {
        // connectionId is empty at this point — will be set when SignalR connects
        var player = await _roomService.JoinRoomAsync(request.RoomCode, request.UserId, string.Empty);
        var room = await _roomService.GetRoomByCodeAsync(request.RoomCode);
        return Ok(new { Player = player, Room = room });
    }
}
