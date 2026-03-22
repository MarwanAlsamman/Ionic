using AutoMapper;
using QuizGame.Application.DTOs;
using QuizGame.Application.Interfaces;
using QuizGame.Domain.Entities;
using QuizGame.Domain.Interfaces;

namespace QuizGame.Application.Services;

public class UserService : IUserService
{
    private readonly IRepository<User> _userRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<UserService> _logger;

    public UserService(IRepository<User> userRepo, IMapper mapper, ILogger<UserService> logger)
    {
        _userRepo = userRepo;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<UserDto> CreateUserAsync(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
            throw new ArgumentException("Username cannot be empty.");

        // Prevent duplicate usernames
        var existing = await _userRepo.FirstOrDefaultAsync(u =>
            u.Username.ToLower() == username.ToLower());

        if (existing != null)
        {
            _logger.LogInformation("User '{Username}' already exists, returning existing user.", username);
            return _mapper.Map<UserDto>(existing);
        }

        var user = new User { Username = username.Trim() };
        await _userRepo.AddAsync(user);

        _logger.LogInformation("Created new user '{Username}' with Id {Id}.", user.Username, user.Id);
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto?> GetUserByIdAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id);
        return user == null ? null : _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto?> GetUserByUsernameAsync(string username)
    {
        var user = await _userRepo.FirstOrDefaultAsync(u =>
            u.Username.ToLower() == username.ToLower());
        return user == null ? null : _mapper.Map<UserDto>(user);
    }
}
