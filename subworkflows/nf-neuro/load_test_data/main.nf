

def locate_local_cache () {
    // Find cache location for test archives, in order of preference:
    // 1. Using environment variable $NFNEURO_TEST_DATA_HOME
    // 2. Using environment variable $XDG_DATA_HOME
    // 3. Using default location $HOME/.local/share
    //
    // Location selected is appended with 'nf-neuro-test-archives'.
    // If the location does not exist, it is created.

    def storage = file(
        System.getenv('NFNEURO_TEST_DATA_HOME') ?:
        System.getenv('XDG_DATA_HOME') ?:
        "${System.getenv('HOME')}/.local/share"
    )
    def cache_location = file("$storage/nf-neuro-test-archives")

    if ( !cache_location.exists() ) {
        try {
            cache_location.mkdirs()
        }
        catch (Exception _e) {
            error "Failed to create cache location: $cache_location | $_e"
        }
    }

    return cache_location
}

def locate_remote_cache () {
    return "$params.test_data_remote/$params.test_database_path"
}

def load_manifest () {
    // Load test data associations from params.test_data_associations
    // which must be a map of test data identifiers [filename: identifier]

    if ( ! params.test_data_associations ) {
        error """
        No test data associations provided, cannot create cache manifest. Please
        provide a map of test data identifiers [filename: identifier] using
        params.test_data_associations.
        """
    }

    return params.test_data_associations
}

def validate_cache_entry ( name, manager ) {
    // Check if the cache entry is present in the manifest

    if ( !manager.manifest[name] ) {
        error "Invalid cache entry supplied : $name"
    }

}

def add_cache_entry ( name, manager ) {
    // Add the test data archive as an entry in the cache. The archive is
    // fetched from the remote location and stored in the cache location.
    // The given name is validated against the manifest before adding.

    manager.validate_entry(name)

    def identifier = "${manager.manifest[name]}"
    def cache_entry = file("${manager.cache_location}/$identifier")
    def remote_subpath = "${identifier[0..1]}/${identifier[2..-1]}"
    def remote_entry = file("$manager.remote_location/$remote_subpath")

    try {
        remote_entry.copyTo(cache_entry)
    }
    catch (Exception _e) {
        manager.delete_entry(name)
        error "Failed to download test archive: $name | $_e"
    }

    return cache_entry
}

def get_cache_entry ( name, manager ) {
    // Retrieve the cache entry for the given test data archive name.
    // If the entry does not exist, it is added to the cache. The add
    // operation will validate the name against the manifest.

    def identifier = "${manager.manifest[name]}"
    def cache_entry = file("${manager.cache_location}/$identifier")

    if ( !cache_entry.exists() ) manager.add_entry(name)

    return cache_entry
}

def delete_cache_entry ( name, manager ) {
    // Delete the cache entry for the given test data archive name.

    def identifier = "${manager.manifest[name]}"
    def cache_entry = file("${manager.cache_location}/$identifier")
    if ( cache_entry.exists() ) {
        try {
            cache_entry.delete()
        }
        catch (Exception _e) {
            error "Failed to delete cache entry for test archive: $name | $_e"
        }
    }
}

def update_cache_entry ( name, manager ) {
    // Update the cache entry for the given test data archive name. The
    // procedure uses add to carry the update, but deletes the entry first
    // if it exists. The add operation will validate the name against
    // the manifest.

    manager.delete_entry(name)
    manager.add_entry(name)
}

def setup_cache () {
    // Build a cache manager to encapsulate interaction with the test data cache.
    // The manager follows simple CRUD operation to handle update and retrieval of
    // test data archives from the cache and the remote location.

    def cache_manager = new Expando(
        remote_location: locate_remote_cache(),
        cache_location: locate_local_cache(),
        manifest: load_manifest()
    )
    cache_manager.validate_entry = { v -> validate_cache_entry( v, cache_manager ) }
    cache_manager.add_entry = { v -> add_cache_entry(v, cache_manager) }
    cache_manager.get_entry = { v -> get_cache_entry(v, cache_manager) }
    cache_manager.delete_entry = { v -> delete_cache_entry(v, cache_manager) }
    cache_manager.update_entry = { v -> update_cache_entry(v, cache_manager) }

    return cache_manager
}

def unzip_test_archive ( archive, destination ) {
    // Unzip the test data archive to the destination directory.
    // Exception are not handled here, and are propagated to the caller.

    def content = null
    try {
        content = new java.util.zip.ZipFile("$archive")
        content.entries().each{ entry ->
            def local_target = file("$destination/${entry.getName()}")
            if (entry.isDirectory()) {
                local_target.mkdirs();
            } else {
                local_target.getParent().mkdirs();
                file("$local_target").withOutputStream{
                    out -> out << content.getInputStream(entry)
                }
            }
        }
        content.close()
    }
    catch (Exception _e) {
        if (content) content.close()
        throw _e
    }
}

def fetch_archive ( name, destination, manager ) {
    // Unzip all archive content to destination
    try {
        unzip_test_archive(manager.get_entry(name), destination)

        return destination.resolve("${name.take(name.lastIndexOf('.'))}")
    }
    catch (java.util.zip.ZipException _e) {
        try {
            manager.delete_entry(name)
            unzip_test_archive(manager.get_entry(name), destination)

            return destination.resolve("${name.take(name.lastIndexOf('.'))}")
        }
        catch (Exception _ee) {
            error "Failed to fetch test archive: $name | $_ee"
        }
    }
}

workflow LOAD_TEST_DATA {

    take:
    ch_archive
    test_data_prefix

    main:
    manager = setup_cache()

    test_data_path = java.nio.file.Files.createTempDirectory("$test_data_prefix")
    ch_test_data_directory = ch_archive.map{ archive ->
        fetch_archive(archive, test_data_path, manager)
    }

    emit:
    test_data_directory = ch_test_data_directory  // channel: [ test_data_directory ]
}
