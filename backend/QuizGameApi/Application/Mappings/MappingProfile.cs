using AutoMapper;
using QuizGame.Application.DTOs;
using QuizGame.Domain.Entities;

namespace QuizGame.Application.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // User → UserDto
        CreateMap<User, UserDto>();

        // Player → PlayerDto (Username comes from the User navigation property)
        CreateMap<Player, PlayerDto>()
            .ForMember(d => d.Username, opt => opt.MapFrom(s => s.User != null ? s.User.Username : "Unknown"));

        // GameRoom → GameRoomDto
        CreateMap<GameRoom, GameRoomDto>()
            .ForMember(d => d.Status, opt => opt.MapFrom(s => s.Status.ToString()))
            .ForMember(d => d.Players, opt => opt.MapFrom(s => s.Players));

        // Question → QuestionDto (no CorrectOption — hidden from client during play)
        CreateMap<Question, QuestionDto>()
            .ForMember(d => d.Difficulty, opt => opt.MapFrom(s => s.Difficulty.ToString()))
            .ForMember(d => d.RoundNumber, opt => opt.Ignore())
            .ForMember(d => d.TotalRounds, opt => opt.Ignore());

        // Question → QuestionRevealDto (includes CorrectOption)
        CreateMap<Question, QuestionRevealDto>()
            .ForMember(d => d.Difficulty, opt => opt.MapFrom(s => s.Difficulty.ToString()));
    }
}
