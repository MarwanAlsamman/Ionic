using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using QuizGame.Domain.Interfaces;
using QuizGame.Infrastructure.Data;

namespace QuizGame.Infrastructure.Repositories;

/// <summary>
/// Generic EF Core repository implementation.
/// Registered as Scoped so each HTTP request / SignalR invocation
/// gets its own DbContext instance.
///
/// To migrate to SQL Server later:
///   1. Change AddDbContext provider in Program.cs
///   2. Add EF Core migrations
///   3. No code changes needed here.
/// </summary>
public class Repository<T> : IRepository<T> where T : class
{
    private readonly QuizGameDbContext _context;
    private readonly DbSet<T> _set;

    public Repository(QuizGameDbContext context)
    {
        _context = context;
        _set = context.Set<T>();
    }

    public async Task<T?> GetByIdAsync(Guid id) =>
        await _set.FindAsync(id);

    public async Task<IEnumerable<T>> GetAllAsync() =>
        await _set.ToListAsync();

    public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate) =>
        await _set.Where(predicate).ToListAsync();

    public async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate) =>
        await _set.FirstOrDefaultAsync(predicate);

    public async Task AddAsync(T entity)
    {
        await _set.AddAsync(entity);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(T entity)
    {
        _set.Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var entity = await _set.FindAsync(id);
        if (entity != null)
        {
            _set.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate) =>
        await _set.AnyAsync(predicate);
}
