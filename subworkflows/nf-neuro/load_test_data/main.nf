import java.nio.file.Files

def fetch_archive ( name, destination, remote, database, data_identifiers ) {
    // Find cache location for test archives
    def storage = file(
        System.getenv('NFSCIL_TEST_DATA_HOME') ?:
        System.getenv('XDG_DATA_HOME') ?:
        "${System.getenv('HOME')}/.local/share"
    )
    def cache_location = file("$storage/nf-scil-test-archives")
    if ( !cache_location.exists() ) cache_location.mkdirs()

    // Fetch file from remote if not present in cache
    def data_id = data_identifiers[name]
    if ( !data_id ) {
        error "Invalid test data identifier supplied: $name"
    }

    def cache_entry = file("$cache_location/$data_id")
    if ( !cache_entry.exists() ) {
        def remote_entry = "${data_id[0..1]}/${data_id[2..-1]}"
        file("$remote/$database/$remote_entry").copyTo(cache_entry)
    }

    // Unzip all archive content to destination
    def content = new java.util.zip.ZipFile("$cache_entry")
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

    return destination.resolve("${name.take(name.lastIndexOf('.'))}")
}

workflow LOAD_TEST_DATA {

    take:
    ch_archive
    test_data_prefix

    main:

    ch_versions = Channel.empty()
    test_data_path = Files.createTempDirectory("$test_data_prefix")
    ch_test_data_directory = ch_archive.map{ archive ->
        fetch_archive(
            archive, test_data_path,
            params.nf_scil_test_data_remote,
            params.nf_scil_test_database_path,
            params.nf_scil_test_data_associations
        )
    }

    emit:
    test_data_directory = ch_test_data_directory  // channel: [ test_data_directory ]
}
