package ohos_app_cangjie_entry.services.github

import std.collection.ArrayList
import std.convert.*
import ohos_app_cangjie_entry.domain.GitHubRepositoryCardSnapshot
import ohos_app_cangjie_entry.infra.databoard.{dataBoardGet, dataBoardSet}

let GITHUB_FAVORITES_STORE_KEY = "github_favorite_repositories"

func escapeFavoriteField(value: String): String {
    value.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")
}

func unescapeFavoriteField(value: String): String {
    var result = ""
    var index = 0
    while (index < value.size) {
        if (value[index..index + 1] == "\\" && index + 1 < value.size) {
            let next = value[index + 1..index + 2]
            if (next == "n") {
                result += "\n"
            } else if (next == "t") {
                result += "\t"
            } else {
                result += next
            }
            index += 2
            continue
        }
        result += value[index..index + 1]
        index += 1
    }
    result
}

func splitFavoriteFields(record: String): ArrayList<String> {
    let fields = ArrayList<String>()
    var current = ""
    var index = 0
    var escaping = false
    while (index < record.size) {
        let ch = record[index..index + 1]
        if (escaping) {
            current += "\\" + ch
            escaping = false
            index += 1
            continue
        }
        if (ch == "\\") {
            escaping = true
            index += 1
            continue
        }
        if (ch == "\t") {
            fields.add(unescapeFavoriteField(current))
            current = ""
            index += 1
            continue
        }
        current += ch
        index += 1
    }
    fields.add(unescapeFavoriteField(current))
    fields
}

func serializeFavorite(snapshot: GitHubRepositoryCardSnapshot): String {
    "${escapeFavoriteField(snapshot.name)}\t${escapeFavoriteField(snapshot.summary)}\t${escapeFavoriteField(snapshot.repoUrl)}\t${if (snapshot.isPrivate) { "1" } else { "0" }}\t${if (snapshot.isFork) { "1" } else { "0" }}\t${snapshot.starCount}\t${if (snapshot.viewerStarred) { "1" } else { "0" }}"
}

func deserializeFavorite(record: String): ?GitHubRepositoryCardSnapshot {
    let fields = splitFavoriteFields(record)
    if (fields.size < 7) {
        return None
    }
    Some(
        GitHubRepositoryCardSnapshot(
            fields[0],
            fields[1],
            fields[2],
            fields[3] == "1",
            fields[4] == "1",
            Int64.parse(fields[5]),
            fields[6] == "1"
        )
    )
}

func findFavoriteIndex(
    items: ArrayList<GitHubRepositoryCardSnapshot>,
    repositoryName: String
): Int64 {
    for (index in 0..items.size) {
        if (items[index].name == repositoryName) {
            return index
        }
    }
    -1
}

public func loadStoredFavoriteRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
    let items = ArrayList<GitHubRepositoryCardSnapshot>()
    let raw = dataBoardGet(GITHUB_FAVORITES_STORE_KEY)
    if (raw == "") {
        return items
    }
    for (record in raw.split("\n")) {
        if (record == "") {
            continue
        }
        if (let Some(snapshot) <- deserializeFavorite(record)) {
            items.add(snapshot)
        }
    }
    items
}

public func persistStoredFavoriteRepositories(
    items: ArrayList<GitHubRepositoryCardSnapshot>
): Unit {
    var raw = ""
    for (index in 0..items.size) {
        if (index > 0) {
            raw += "\n"
        }
        raw += serializeFavorite(items[index])
    }
    dataBoardSet(GITHUB_FAVORITES_STORE_KEY, raw)
}

public func syncFavoriteRepositories(
    favorites: ArrayList<GitHubRepositoryCardSnapshot>,
    liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
): ArrayList<GitHubRepositoryCardSnapshot> {
    let synced = ArrayList<GitHubRepositoryCardSnapshot>()
    for (favorite in favorites) {
        let liveIndex = findFavoriteIndex(liveRepositories, favorite.name)
        if (liveIndex >= 0) {
            synced.add(liveRepositories[liveIndex])
        } else {
            synced.add(favorite)
        }
    }
    persistStoredFavoriteRepositories(synced)
    synced
}
