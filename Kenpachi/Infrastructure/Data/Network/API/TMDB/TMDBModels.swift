// TMDBModels.swift
// TMDB API response models
// Defines data structures for TMDB API responses

import Foundation

/// Generic paged response from TMDB API
struct TMDBPagedResponse<T: Decodable>: Decodable {
  let page: Int
  let results: [T]
  let totalPages: Int
  let totalResults: Int
}

/// TMDB movie model
struct TMDBMovie: Decodable {
  let id: Int
  let title: String
  let originalTitle: String?
  let overview: String?
  let posterPath: String?
  let backdropPath: String?
  let releaseDate: String?
  let voteAverage: Double?
  let voteCount: Int?
  let popularity: Double?
  let originalLanguage: String?
  let genreIds: [Int]?
  let genres: [TMDBGenre]?
  let adult: Bool?
  let runtime: Int?
  let status: String?
  let tagline: String?
  let homepage: String?
  let productionCompanies: [TMDBProductionCompany]?
  let credits: TMDBCredits?
  let recommendations: TMDBRecommendationsResponse?
  let videos: TMDBVideosResponse?

  /// Converts TMDB movie to domain Content model
  func toContent() -> Content {
    Content(
      id: String(id),
      type: .movie,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      releaseDate: parseDate(releaseDate),
      voteAverage: voteAverage,
      voteCount: voteCount,
      popularity: popularity,
      originalLanguage: originalLanguage,
      genreIds: genreIds,
      genres: genres?.map { $0.toGenre() },
      adult: adult ?? false,
      runtime: runtime,
      status: status,
      tagline: tagline,
      homepage: homepage,
      productionCompanies: productionCompanies?.map { $0.name },
      cast: credits?.cast.prefix(10).map { $0.toCast() },
      trailerUrl: videos?.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" })?
        .youtubeURL,
      recommendations: recommendations?.results.prefix(10).compactMap { result in
        Content(
          id: String(result.id),
          type: .movie,
          title: result.title ?? "",
          posterPath: result.posterPath,
          backdropPath: result.backdropPath
        )
      }
    )
  }

  /// Parses date string to Date object
  private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString)
  }

  /// Checks if the movie has been released
  func isReleased() -> Bool {
    // If no release date, consider it unreleased
    guard let releaseDateString = releaseDate else { return false }

    // Parse the release date
    guard let releaseDate = parseDate(releaseDateString) else { return false }

    // Check if release date is in the past or today
    return releaseDate <= Date()
  }
}

/// TMDB TV show model
struct TMDBTVShow: Decodable {
  let id: Int
  let name: String
  let originalName: String?
  let overview: String?
  let posterPath: String?
  let backdropPath: String?
  let firstAirDate: String?
  let voteAverage: Double?
  let voteCount: Int?
  let popularity: Double?
  let originalLanguage: String?
  let genreIds: [Int]?
  let genres: [TMDBGenre]?
  let numberOfSeasons: Int?
  let numberOfEpisodes: Int?
  let status: String?
  let homepage: String?
  let productionCompanies: [TMDBProductionCompany]?
  var seasons: [TMDBSeason]?
  let credits: TMDBCredits?
  let recommendations: TMDBRecommendationsResponse?
  let videos: TMDBVideosResponse?

  /// Converts TMDB TV show to domain Content model
  func toContent() -> Content {
    Content(
      id: String(id),
      type: .tvShow,
      title: name,
      originalTitle: originalName,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      releaseDate: parseDate(firstAirDate),
      voteAverage: voteAverage,
      voteCount: voteCount,
      popularity: popularity,
      originalLanguage: originalLanguage,
      genreIds: genreIds,
      genres: genres?.map { $0.toGenre() },
      adult: false,
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      status: status,
      homepage: homepage,
      productionCompanies: productionCompanies?.map { $0.name },
      seasons: seasons?.map { $0.toSeason() },
      cast: credits?.cast.prefix(10).map { $0.toCast() },
      trailerUrl: videos?.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" })?
        .youtubeURL,
      recommendations: recommendations?.results.prefix(10).compactMap { result in
        Content(
          id: String(result.id),
          type: .tvShow,
          title: result.title ?? "",
          posterPath: result.posterPath,
          backdropPath: result.backdropPath
        )
      }
    )
  }

  /// Parses date string to Date object
  private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString)
  }

  /// Checks if the TV show has been released (first episode aired)
  func isReleased() -> Bool {
    // If no first air date, consider it unreleased
    guard let firstAirDateString = firstAirDate else { return false }

    // Parse the first air date
    guard let firstAirDate = parseDate(firstAirDateString) else { return false }

    // Check if first air date is in the past or today
    return firstAirDate <= Date()
  }
}

// MARK: - Supporting Models

/// TMDB Recommendations Response (simplified to avoid circular reference)
struct TMDBRecommendationsResponse: Decodable {
  let results: [TMDBRecommendationItem]
}

/// Simplified recommendation item
struct TMDBRecommendationItem: Decodable {
  let id: Int
  let title: String?
  let posterPath: String?
  let backdropPath: String?
}

/// TMDB Genre model
struct TMDBGenre: Decodable {
  let id: Int
  let name: String

  func toGenre() -> Genre {
    Genre(id: id, name: name)
  }
}

/// TMDB Production Company model
struct TMDBProductionCompany: Decodable {
  let id: Int
  let name: String
  let logoPath: String?
  let originCountry: String?
}

/// TMDB Season model
struct TMDBSeason: Decodable {
  let id: Int
  let seasonNumber: Int
  let name: String
  let overview: String?
  let posterPath: String?
  let airDate: String?
  let episodeCount: Int?
  let episodes: [TMDBEpisode]?

  func toSeason() -> Season {
    Season(
      id: String(seasonNumber),
      seasonNumber: seasonNumber,
      name: name,
      overview: overview,
      posterPath: posterPath,
      airDate: parseDate(airDate),
      episodeCount: episodeCount ?? episodes?.count ?? 0,
      episodes: episodes?.map { $0.toEpisode() }
    )
  }

  private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString)
  }
}

/// TMDB Episode model
struct TMDBEpisode: Decodable {
  let id: Int
  let episodeNumber: Int
  let seasonNumber: Int
  let name: String
  let overview: String?
  let stillPath: String?
  let airDate: String?
  let runtime: Int?
  let voteAverage: Double?

  func toEpisode() -> Episode {
    Episode(
      id: String(episodeNumber),
      episodeNumber: episodeNumber,
      seasonNumber: seasonNumber,
      name: name,
      overview: overview,
      stillPath: stillPath,
      airDate: parseDate(airDate),
      runtime: runtime,
      voteAverage: voteAverage
    )
  }

  private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString)
  }
}

/// TMDB Credits model
struct TMDBCredits: Decodable {
  let cast: [TMDBCast]
  let crew: [TMDBCrew]
}

/// TMDB Cast member model
struct TMDBCast: Decodable {
  let id: Int
  let name: String
  let character: String?
  let profilePath: String?
  let order: Int?

  func toCast() -> Cast {
    Cast(
      id: id,
      name: name,
      character: character,
      profilePath: profilePath,
      order: order
    )
  }
}

/// TMDB Crew member model
struct TMDBCrew: Decodable {
  let id: Int
  let name: String
  let job: String?
  let department: String?
  let profilePath: String?
}

/// TMDB Videos Response model
struct TMDBVideosResponse: Decodable {
  let results: [TMDBVideo]
}

/// TMDB Video model
struct TMDBVideo: Decodable {
  let id: String
  let key: String
  let name: String
  let site: String
  let type: String
  let official: Bool?

  var youtubeURL: String? {
    guard site == "YouTube" else { return nil }
    return "https://www.youtube.com/watch?v=\(key)"
  }
}
