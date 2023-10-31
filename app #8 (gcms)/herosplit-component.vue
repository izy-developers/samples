<template>
  <section
    v-intersection-section="[elementId, headline]"
    :class="[
      'relative overflow-hidden',
      backgroundColorRef,
      colorsRef,
      sectionStyles.margin,
      sectionStyles.padding || 'py-10 lg:py-20',
    ]"
    :data-sb-field-path="annotationPrefix"
  >
    <AnchorBlock :element-id="elementId" />
    <div
      class="flex flex-col gap-12 lg:flex-row xl:gap-16"
      :class="{ container: applyImageContainer }"
    >
      <div
        data-sb-field-path=".imageContainer"
        class="flex basis-full flex-col lg:basis-1/2"
        :class="[
          $mapStyles({
            textAlign: imageContainerStyles.textAlign || 'center',
            padding: imageContainerStyles.padding,
            justifyContent: imageContainerStyles.justifyContent || 'center',
          }),
          { 'lg:order-1': imagePosition === 'right' },
        ]"
      >
        <div :class="$mapStyles({ aspectRatio: mediaAspectRatio })">
          <LazyPrimitiveMediaBlock
            :media="media"
            :mediaClass="[
              'w-full h-full',
              {
                'object-contain': imageFormat === 'contain',
                'object-cover': imageFormat === 'cover',
              },
            ]"
          />
        </div>
        <div
          v-if="caption"
          v-html="$md(caption)"
          data-sb-field-path=".caption"
          class="caption-text container prose prose-sm mt-4"
        />
        <div
          v-if="(buttons?.length || searchComponent) && isArrange3"
          class="mt-10 flex flex-col gap-10 lg:hidden"
          :class="{ 'w-full': stretchButtonsOnMobile }"
        >
          <div
            v-if="buttons?.length"
            class="bio-buttons-container w-full flex-wrap md:justify-center lg:justify-start"
            :class="
              $mapStyles({
                justifyContent: {
                  left: 'flex-start',
                  center: 'center',
                  right: 'flex-end',
                }[adjustTextAlignOnMobile],
              })
            "
            data-sb-field-path=".buttons"
          >
            <TheDynamicComponent
              v-for="(action, idx) in buttons"
              :key="`${action.__metadata.id} - ${idx}`"
              :data="action"
              :wrapperClass="{
                'max-md:w-full':
                  stretchButtonsOnMobile &&
                  action.__metadata.modelName === 'Button',
              }"
              :annotation-prefix="`.${idx}`"
            />
          </div>
          <div v-if="searchComponent" class="search-component w-full text-left">
            <SearchBasic v-bind="searchComponent" />
          </div>
        </div>
      </div>
      <div
        data-sb-field-path=".contentContainer"
        class="content-container flex basis-full flex-col md:items-center md:text-center lg:basis-1/2"
        :class="[
          $mapStyles({
            textAlign: adjustTextAlignOnMobile,
            alignItems: {
              left: 'flex-start',
              center: 'center',
              right: 'flex-end',
            }[adjustTextAlignOnMobile],
          }),
          {
            'max-lg:-order-1': isArrange2 || isArrange3,
            'container lg:max-w-[477px] lg:px-0 xl:max-w-[590px] 2xl:max-w-[740px]':
              !applyImageContainer,
            'lg:ml-0 lg:mr-auto lg:pr-8':
              !applyImageContainer && imagePosition === 'left',
            'lg:ml-auto lg:mr-0 lg:pl-8':
              !applyImageContainer && imagePosition === 'right',
          },
          $mapStyles({
            padding: contentContainerStyles.padding,
            justifyContent: contentContainerStyles.justifyContent || 'center',
          }),
          $mapStyle(
            'textAlign',
            contentContainerStyles.textAlign
              ? 'lg-' + contentContainerStyles.textAlign
              : 'lg-left',
          ),
        ]"
      >
        <div
          v-if="title"
          class="title-text prose prose-base lg:prose-lg"
          data-sb-field-path=".title"
          v-html="$md(title)"
        />
        <div
          v-if="description"
          class="description-text prose prose-base mt-7 lg:prose-lg"
          data-sb-field-path=".description"
          v-html="$md(description)"
        />
        <div v-if="accordion" class="w-full" data-sb-field-path=".accordion">
          <LazyAccordionRow
            :qaList="accordion"
            :backgroundColorRef="backgroundColorRef"
            :colorRef="colorsRef"
          />
        </div>
        <div
          v-if="(buttons?.length || searchComponent) && isArrange3"
          class="mt-10 flex flex-col gap-10 max-lg:hidden"
        >
          <div
            v-if="buttons?.length"
            class="bio-buttons-container w-full flex-wrap"
            data-sb-field-path=".buttons"
          >
            <TheDynamicComponent
              v-for="(action, idx) in buttons"
              :key="`${action.__metadata.id} - ${idx}`"
              :data="action"
              :annotation-prefix="`.${idx}`"
            />
          </div>
          <div v-if="searchComponent" class="search-component w-full">
            <SearchBasic v-bind="searchComponent" />
          </div>
        </div>
        <div
          v-if="(buttons?.length || searchComponent) && !isArrange3"
          class="mt-10 flex flex-col gap-10"
          :class="{ 'w-full': stretchButtonsOnMobile }"
        >
          <div
            v-if="buttons?.length"
            class="bio-buttons-container flex-wrap md:justify-center lg:justify-start"
            :class="
              $mapStyles({
                justifyContent: {
                  left: 'flex-start',
                  center: 'center',
                  right: 'flex-end',
                }[adjustTextAlignOnMobile],
              })
            "
            data-sb-field-path=".buttons"
          >
            <TheDynamicComponent
              v-for="(action, idx) in buttons"
              :key="`${action.__metadata.id} - ${idx}`"
              :data="action"
              :wrapperClass="{
                'max-md:w-full':
                  stretchButtonsOnMobile &&
                  action.__metadata.modelName === 'Button',
              }"
              :annotation-prefix="`.${idx}`"
            />
          </div>
          <div v-if="searchComponent" class="search-component w-full text-left">
            <SearchBasic v-bind="searchComponent" />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const {
  colors = 'colors-a',
  backgroundColor = 'bg-color-none',
  styles,
  imageFormat = 'cover',
  adjustTextAlignOnMobile = 'center',
  imagePosition = 'left',
  mediaAspectRatio = '1:1',
  applyImageContainer = true,
  arrangementOnMobile = 'image-content-actions',
  elementId,
} = defineProps<{
  title?: string;
  description?: string;
  annotationPrefix: string;
  buttons?: any[];
  media?: any;
  applyImageContainer?: boolean;
  adjustTextAlignOnMobile?: 'left' | 'center' | 'right';
  stretchButtonsOnMobile?: boolean;
  accordion?: any;
  mediaAspectRatio?: '1:1' | '2:3' | '3:2' | 'auto';
  colors?: 'colors-a' | 'colors-b' | 'colors-c';
  backgroundColor?:
    | 'bg-color-none'
    | 'bg-color-primary'
    | 'bg-color-secondary'
    | 'bg-color-complementary'
    | 'bg-color-addit-a'
    | 'bg-color-addit-b'
    | 'bg-color-addit-c';
  imagePosition?: 'left' | 'right';
  imageFormat?: 'contain' | 'cover';
  arrangementOnMobile?:
    | 'image-content-actions'
    | 'content-actions-image'
    | 'content-image-actions';
  caption?: string;
  searchComponent?: any;
  elementId?: string;
  headline?: string;
  styles?: any;
  __metadata?: any;
}>();

const backgroundColorRef = computed(() => backgroundColor);
const colorsRef = computed(() => colors);

const sectionStyles = computed(() => styles?.self || {});
const imageContainerStyles = computed(() => styles?.imageContainer || {});
const contentContainerStyles = computed(() => styles?.contentContainer || {});

const isArrange2 = computed(
  () => arrangementOnMobile === 'content-actions-image',
);
const isArrange3 = computed(
  () => arrangementOnMobile === 'content-image-actions',
);
</script>

<style scoped lang="postcss">
.bg-color-none {
  @apply bg-main;
}
.bg-color-primary {
  @apply bg-primary;
}
.bg-color-secondary {
  @apply bg-secondary;
}
.bg-color-complementary {
  @apply bg-complementary;
}
.bg-color-addit-a {
  @apply bg-additional-color-a;
}
.bg-color-addit-b {
  @apply bg-additional-color-b;
}
.bg-color-addit-c {
  @apply bg-additional-color-c;
}

.caption-text,
.title-text,
.description-text {
  :deep(ul) {
    @apply mx-auto lg:mx-0;
  }
}

.content-container {
  :deep(&.lg\:text-center ul) {
    @apply lg:!mx-auto;
  }
  :deep(&.lg\:text-right ul) {
    @apply lg:!ml-auto;
  }
  :deep(&.lg\:text-right) {
    @apply lg:items-end;
  }
  :deep(&.lg\:text-left) {
    @apply lg:items-start;
  }
  :deep(&.lg\:text-center) {
    @apply lg:items-center;
  }
}

.bg-color-primary,
.bg-color-secondary,
.bg-color-complementary {
  &.colors-a,
  &.colors-b,
  &.colors-c {
    .caption-text,
    .title-text,
    .description-text {
      @apply prose-light;
    }
    :deep(.search-component h2) {
      @apply text-light;
    }
    .bio-component-button-secondary {
      @apply bg-light text-light hover:bg-light;
    }
    .bio-component-button-outlined {
      @apply border-light text-light;
    }
    .bio-component-link {
      @apply text-light hover:text-light/90;
    }
  }
  &.colors-a {
    .bio-component-button-primary {
      @apply bg-light text-primary;
    }
  }
  &.colors-b {
    .bio-component-button-primary {
      @apply bg-light text-secondary;
    }
  }
  &.colors-c {
    .bio-component-button-primary {
      @apply bg-light text-complementary;
    }
  }
}

.bg-color-none,
.bg-color-addit-a,
.bg-color-addit-b,
.bg-color-addit-c {
  &.colors-a {
    .caption-text,
    .title-text,
    .description-text {
      @apply prose-primary;
      :deep(strong) {
        @apply text-primary xl:inline;
      }
    }
    .bio-component-button-outlined {
      @apply border-primary text-primary;
    }
    .bio-component-button-primary {
      @apply bg-primary text-on-primary;
    }
    .bio-component-button-secondary {
      @apply bg-primary text-primary hover:bg-primary;
    }
    .bio-component-link {
      @apply text-primary hover:text-primary/90;
    }
  }
  &.colors-b {
    .caption-text,
    .title-text,
    .description-text {
      @apply prose-secondary;
      :deep(strong) {
        @apply text-secondary xl:inline;
      }
    }
    .bio-component-button-outlined {
      @apply border-secondary text-secondary;
    }
    .bio-component-button-primary {
      @apply bg-secondary text-on-secondary;
    }
    .bio-component-button-secondary {
      @apply bg-secondary text-secondary hover:bg-secondary;
    }
    .bio-component-link {
      @apply text-secondary hover:text-secondary/90;
    }
  }
  &.colors-c {
    .caption-text,
    .title-text,
    .description-text {
      @apply prose-complementary;
      :deep(strong) {
        @apply text-complementary xl:inline;
      }
    }
    .bio-component-button-outlined {
      @apply border-complementary text-complementary;
    }
    .bio-component-button-primary {
      @apply bg-complementary text-on-complementary;
    }
    .bio-component-button-secondary {
      @apply bg-complementary text-complementary hover:bg-complementary;
    }
    .bio-component-link {
      @apply text-complementary hover:text-complementary/90;
    }
  }
}
</style>
