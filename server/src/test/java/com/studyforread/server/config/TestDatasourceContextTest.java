package com.studyforread.server.config;

import static org.assertj.core.api.Assertions.assertThat;

import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class TestDatasourceContextTest {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private Flyway flyway;

    @Test
    void startsWithDatasourceAndFlyway() throws Exception {
        assertThat(flyway).isNotNull();

        try (var connection = dataSource.getConnection();
                var statement = connection.createStatement();
                var resultSet = statement.executeQuery("select 1")) {
            assertThat(resultSet.next()).isTrue();
            assertThat(resultSet.getInt(1)).isEqualTo(1);
        }
    }
}
