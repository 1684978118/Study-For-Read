package com.studyforread.server.study.provider;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.List;
import org.junit.jupiter.api.Test;

class StudyProviderRouterTest {

    @Test
    void routerCanReturnLookupResultFromLocalFallbackProvider() {
        var router = new StudyProviderRouter(List.of(new LocalFallbackStudyProvider()));

        var result = router.lookup("koko", "ja", "zh-CN", null);

        assertThat(result.providerName()).isEqualTo("local_fallback");
        assertThat(result.kind()).isEqualTo("lexeme");
        assertThat(result.lexeme()).isNotNull();
        assertThat(result.lexeme().surface()).isEqualTo("koko");
        assertThat(result.lexeme().definition()).contains("local fallback");
    }

    @Test
    void routerCanReturnParagraphTranslationResultFromLocalFallbackProvider() {
        var router = new StudyProviderRouter(List.of(new LocalFallbackStudyProvider()));

        var result = router.translateParagraph("first paragraph", "ja", "zh-CN");

        assertThat(result.providerName()).isEqualTo("local_fallback");
        assertThat(result.translatedText()).contains("local fallback");
        assertThat(result.cached()).isFalse();
        assertThat(result.message()).isNull();
    }

    @Test
    void routerCanReturnAnnotationTokensFromLocalFallbackProvider() {
        var router = new StudyProviderRouter(List.of(new LocalFallbackStudyProvider()));

        var result = router.annotate("first sentence", "ja");

        assertThat(result.providerName()).isEqualTo("local_fallback");
        assertThat(result.tokens()).isNotEmpty();
        assertThat(result.tokens().getFirst().text()).isEqualTo("first");
    }

    @Test
    void providerResultIncludesProviderName() {
        var provider = new LocalFallbackStudyProvider();

        assertThat(provider.lookup("word", "ja", "zh-CN", null).providerName()).isEqualTo("local_fallback");
        assertThat(provider.translateParagraph("paragraph", "ja", "zh-CN").providerName())
                .isEqualTo("local_fallback");
        assertThat(provider.annotate("token text", "ja").providerName()).isEqualTo("local_fallback");
    }

    @Test
    void providerDoesNotStoreSourceTextAsInternalState() throws Exception {
        var provider = new LocalFallbackStudyProvider();

        provider.lookup("lookup source", "ja", "zh-CN", "context");
        provider.translateParagraph("translation source", "ja", "zh-CN");
        provider.annotate("annotation source", "ja");

        for (var field : provider.getClass().getDeclaredFields()) {
            if (Modifier.isStatic(field.getModifiers())) {
                continue;
            }

            field.setAccessible(true);
            assertThat(field.get(provider))
                    .isNotEqualTo("lookup source")
                    .isNotEqualTo("context")
                    .isNotEqualTo("translation source")
                    .isNotEqualTo("annotation source");
        }
    }

    @Test
    void routerDoesNotRequireRealProviderSecrets() throws Exception {
        var routerClass = StudyProviderRouter.class;
        var providerClass = LocalFallbackStudyProvider.class;

        assertThat(hasDeclaredFieldNamed(routerClass, "apiKey")).isFalse();
        assertThat(hasDeclaredFieldNamed(routerClass, "secret")).isFalse();
        assertThat(hasDeclaredFieldNamed(providerClass, "apiKey")).isFalse();
        assertThat(hasDeclaredFieldNamed(providerClass, "secret")).isFalse();
    }

    private boolean hasDeclaredFieldNamed(Class<?> type, String fieldName) {
        for (Field field : type.getDeclaredFields()) {
            if (field.getName().equalsIgnoreCase(fieldName)) {
                return true;
            }
        }
        return false;
    }
}
