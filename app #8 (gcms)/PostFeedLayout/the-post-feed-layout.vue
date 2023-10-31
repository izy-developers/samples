<template>
  <div class="flex flex-1 flex-col justify-center">
    <div class="flex flex-col" data-sb-field-path=".topSections">
      <TheDynamicComponent
        v-for="(section, idx) of topSections"
        :key="`${section.__metadata.modelName}-${idx}`"
        :annotation-prefix="`.${idx}`"
        :data="section"
      />
    </div>
    <div class="container relative my-14">
      <AnchorBlock :element-id="elementId" />
      <div
        class="grid gap-16"
        :class="showFilters ? 'grid-cols-3' : 'grid-cols-1'"
      >
        <div v-if="showFilters" class="col-span-1">
          <div
            class="sticky top-[calc(var(--main-menu-height)_+_20px)] flex flex-col transition-[top]"
          >
            <div class="flex justify-between">
              <span class="text-xl font-bold">Filter</span>
              <span
                @click="clearFilters"
                class="cursor-pointer text-xl font-bold text-secondary hover:opacity-80"
              >
                Clear filter
              </span>
            </div>
            <div class="mt-8 flex flex-col">
              <ul v-if="!firstRenderLoading" class="flex flex-col gap-4">
                <template v-for="(tag, idx) in tags" :key="idx">
                  <li
                    @click="() => activateTag(idx)"
                    class="flex w-fit cursor-pointer items-center gap-x-2 rounded-full border border-heading px-4 py-2"
                    :class="tag.active && 'bg-secondary text-light'"
                  >
                    <span>{{ tag.name }}</span>
                    <span
                      class="ml-2"
                      :class="
                        tag.active ? 'text-white opacity-80' : 'text-gray-400'
                      "
                    >
                      {{ tag.count }}
                    </span>
                    <span
                      v-if="tag.active"
                      :class="
                        tag.active ? 'text-white opacity-80' : 'text-gray-400'
                      "
                    >
                      |
                    </span>
                    <div
                      v-if="tag.active"
                      :class="
                        tag.active
                          ? 'stroke-white opacity-80'
                          : 'stroke-gray-400'
                      "
                    >
                      <svg
                        viewBox="0 0 14 14"
                        class="h-4 w-4 group-hover:stroke-gray-700/75"
                      >
                        <path d="M4 4l6 6m0-6l-6 6" />
                      </svg>
                    </div>
                  </li>
                </template>
              </ul>
              <ul v-else class="flex flex-col gap-4">
                <li
                  v-for="id in 7"
                  :key="id"
                  role="status"
                  class="h-10 animate-pulse rounded-full bg-gray-200"
                  :class="[
                    id == 1 && 'w-1/2',
                    id == 2 && 'w-3/4',
                    id == 3 && 'w-4/5',
                    id == 4 && 'w-5/6',
                    id == 5 && 'w-2/3',
                    id == 6 && 'w-3/4',
                    id == 7 && 'w-1/2',
                  ]"
                />
                <span class="sr-only">Loading...</span>
              </ul>
            </div>
          </div>
        </div>
        <div
          class="flex flex-col"
          :class="showFilters ? 'col-span-2' : 'col-span-1'"
        >
          <div
            class="grid grid-cols-1 gap-10"
            :class="
              showFilters
                ? 'sm:grid-cols-2'
                : 'sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4'
            "
            data-sb-field-path=".postFeed"
          >
            <template v-if="!firstRenderLoading">
              <template v-if="!pending">
                <article
                  v-for="post in posts"
                  :key="post.id"
                  class="flex flex-col items-start justify-start"
                >
                  <div class="relative w-full">
                    <LazyPrimitiveImageBlock
                      :image="post.featuredImage"
                      image-class="aspect-[16/9] w-full rounded-2xl bg-gray-100 object-cover sm:aspect-[2/1] md:aspect-[3/2]"
                    />
                    <div
                      class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/10"
                    />
                  </div>
                  <div class="mt-4 max-w-xl">
                    <div
                      v-if="showDate && post.date"
                      class="flex items-center gap-x-4 text-xs"
                    >
                      <time :datetime="post.date" class="text-gray-500">
                        {{ $dateFormat(post.date, locale) }}
                      </time>
                      <!-- <a
                    :href="post.category.href"
                    class="relative z-10 rounded-full bg-gray-50 px-3 py-1.5 font-medium text-gray-600 hover:bg-gray-100"
                    >{{ post.category.title }}</a
                  > -->
                    </div>
                    <div class="group relative">
                      <h2
                        class="mt-3 text-lg font-semibold leading-6 text-heading group-hover:text-grey/90"
                      >
                        <NuxtLink
                          :to="
                            localePath(
                              post.slug === '/' ? '/' : '/' + post.slug
                            )
                          "
                        >
                          <span class="absolute inset-0" />
                          {{ post.title }}
                        </NuxtLink>
                      </h2>
                      <p
                        v-if="showExcerpt && (post.excerpt || post.description)"
                        class="mt-5 line-clamp-3 text-sm leading-6 text-grey"
                      >
                        {{ post.excerpt || post.description }}
                      </p>
                    </div>
                    <div
                      v-if="showAuthor && post.authors"
                      v-for="author in post.authors"
                      :key="author.title"
                      class="relative mt-8 flex items-center gap-x-4"
                    >
                      <LazyPrimitiveImageBlock
                        image-class="h-10 w-10 rounded-full bg-gray-100"
                      />
                      <div class="text-sm leading-6">
                        <p class="font-semibold text-gray-900">
                          {{ author.title }}
                        </p>
                        <p v-if="author.role" class="text-gray-600">
                          {{ author.role }}
                        </p>
                      </div>
                    </div>
                  </div>
                </article>
              </template>
              <template v-else>
                <div
                  v-for="postId in postsIds"
                  :key="postId"
                  role="status"
                  class="animate-pulse"
                >
                  <div
                    class="mb-4 flex aspect-[16/9] items-center justify-center rounded-2xl bg-gray-300 dark:bg-gray-700 sm:aspect-[2/1] md:aspect-[3/2]"
                  >
                    <svg
                      class="h-20 w-20 text-gray-200 dark:text-gray-600"
                      aria-hidden="true"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="currentColor"
                      viewBox="0 0 16 20"
                    >
                      <path
                        d="M14.066 0H7v5a2 2 0 0 1-2 2H0v11a1.97 1.97 0 0 0 1.934 2h12.132A1.97 1.97 0 0 0 16 18V2a1.97 1.97 0 0 0-1.934-2ZM10.5 6a1.5 1.5 0 1 1 0 2.999A1.5 1.5 0 0 1 10.5 6Zm2.221 10.515a1 1 0 0 1-.858.485h-8a1 1 0 0 1-.9-1.43L5.6 10.039a.978.978 0 0 1 .936-.57 1 1 0 0 1 .9.632l1.181 2.981.541-1a.945.945 0 0 1 .883-.522 1 1 0 0 1 .879.529l1.832 3.438a1 1 0 0 1-.031.988Z"
                      />
                      <path
                        d="M5 5V.13a2.96 2.96 0 0 0-1.293.749L.879 3.707A2.98 2.98 0 0 0 .13 5H5Z"
                      />
                    </svg>
                  </div>

                  <div class="mt-8 flex w-full flex-col">
                    <div
                      class="mb-4 h-2.5 w-48 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                    <div
                      class="mb-2.5 h-2 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                    <div
                      class="mb-2.5 h-2 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                    <div
                      class="h-2 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                  </div>

                  <div class="mt-6 flex items-center space-x-3">
                    <svg
                      class="h-10 w-10 text-gray-200 dark:text-gray-700"
                      aria-hidden="true"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z"
                      />
                    </svg>
                    <div>
                      <div
                        class="mb-2 h-2.5 w-32 rounded-full bg-gray-200 dark:bg-gray-700"
                      />
                      <div
                        class="h-2 w-48 rounded-full bg-gray-200 dark:bg-gray-700"
                      />
                    </div>
                  </div>
                  <span class="sr-only">Loading...</span>
                </div>
              </template>
            </template>
            <template v-else>
              <div
                v-for="id in 8"
                :key="id"
                role="status"
                class="animate-pulse"
              >
                <div
                  class="mb-4 flex aspect-[16/9] items-center justify-center rounded-2xl bg-gray-300 dark:bg-gray-700 sm:aspect-[2/1] md:aspect-[3/2]"
                >
                  <svg
                    class="h-20 w-20 text-gray-200 dark:text-gray-600"
                    aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="currentColor"
                    viewBox="0 0 16 20"
                  >
                    <path
                      d="M14.066 0H7v5a2 2 0 0 1-2 2H0v11a1.97 1.97 0 0 0 1.934 2h12.132A1.97 1.97 0 0 0 16 18V2a1.97 1.97 0 0 0-1.934-2ZM10.5 6a1.5 1.5 0 1 1 0 2.999A1.5 1.5 0 0 1 10.5 6Zm2.221 10.515a1 1 0 0 1-.858.485h-8a1 1 0 0 1-.9-1.43L5.6 10.039a.978.978 0 0 1 .936-.57 1 1 0 0 1 .9.632l1.181 2.981.541-1a.945.945 0 0 1 .883-.522 1 1 0 0 1 .879.529l1.832 3.438a1 1 0 0 1-.031.988Z"
                    />
                    <path
                      d="M5 5V.13a2.96 2.96 0 0 0-1.293.749L.879 3.707A2.98 2.98 0 0 0 .13 5H5Z"
                    />
                  </svg>
                </div>

                <div class="mt-8 flex w-full flex-col">
                  <div
                    class="mb-4 h-2.5 w-48 rounded-full bg-gray-200 dark:bg-gray-700"
                  />
                  <div
                    class="mb-2.5 h-2 rounded-full bg-gray-200 dark:bg-gray-700"
                  />
                  <div
                    class="mb-2.5 h-2 rounded-full bg-gray-200 dark:bg-gray-700"
                  />
                  <div class="h-2 rounded-full bg-gray-200 dark:bg-gray-700" />
                </div>

                <div class="mt-6 flex items-center space-x-3">
                  <svg
                    class="h-10 w-10 text-gray-200 dark:text-gray-700"
                    aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z"
                    />
                  </svg>
                  <div>
                    <div
                      class="mb-2 h-2.5 w-32 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                    <div
                      class="h-2 w-48 rounded-full bg-gray-200 dark:bg-gray-700"
                    />
                  </div>
                </div>
                <span class="sr-only">Loading...</span>
              </div>
            </template>
          </div>
          <div
            v-if="!firstRenderLoading"
            class="flex items-center justify-between pt-16"
          >
            <div class="flex flex-1 justify-between sm:hidden">
              <a
                tabindex="0"
                class="relative inline-flex select-none items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700"
                :class="
                  currentPostsPage === 1
                    ? 'cursor-default opacity-30 hover:bg-inherit'
                    : ' cursor-pointer hover:bg-gray-50'
                "
                @click="
                  () =>
                    void (currentPostsPage !== 1 && changePage(undefined, '-'))
                "
              >
                Previous
              </a>
              <a
                tabindex="0"
                class="relative ml-3 inline-flex select-none items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700"
                :class="
                  currentPostsPage !== postsPageCount
                    ? 'cursor-pointer hover:bg-gray-50'
                    : 'cursor-default opacity-30 hover:bg-inherit'
                "
                @click="
                  () =>
                    void (
                      currentPostsPage !== postsPageCount &&
                      changePage(undefined, '+')
                    )
                "
              >
                Next
              </a>
            </div>
            <div
              class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-center"
            >
              <!-- <div>
                <p class="text-sm text-gray-700">
                  Total posts {{ localPosts.length }}
                </p>
              </div> -->
              <div>
                <nav aria-label="Pagination">
                  <Paginate
                    v-model="currentPostsPage"
                    :page-count="postsPageCount"
                    :click-handler="changePage"
                    no-li-surround
                    prev-link-class="relative select-none cursor-pointer inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 [&.disabled]:cursor-default [&.disabled]:text-opacity-30 [&.disabled]:hover:bg-inherit"
                    next-link-class="relative select-none cursor-pointer inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 [&.disabled]:cursor-default [&.disabled]:text-opacity-30 [&.disabled]:hover:bg-inherit"
                    prev-text="<div class='flex h-5 w-5 items-center justify-center text-2xl'> < </div>"
                    next-text="<div class='flex h-5 w-5 items-center justify-center text-2xl'> > </div>"
                    container-class="isolate inline-flex -space-x-px rounded-md shadow-sm"
                    page-link-class="[&.active]:bg-primary [&.active]:focus-visible:outline-primary [&.active]:text-white relative cursor-pointer inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
                  />
                </nav>
              </div>
              <!-- <div>
                <p class="text-sm text-gray-700">
                  Showing {{ posts?.length }} posts
                </p>
              </div> -->
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="flex flex-col" data-sb-field-path=".bottomSections">
      <TheDynamicComponent
        v-for="(section, idx) of bottomSections"
        :key="`${section.__metadata.modelName}-${idx}`"
        :annotation-prefix="`.${idx}`"
        :data="section"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import Paginate from 'vuejs-paginate-next';

const { postFeed } = defineProps<{
  title?: string;
  description?: string;
  breadcrumb?: string;
  slug?: string;
  postFeed?: {
    showExcerpt?: boolean;
    styles?: any;
    elementId?: string;
    numberOfPostsPerPage?: number;
    paginationVariant?: 'Old-school' | 'Show more' | 'Infinity scroll';
    showFilters?: boolean;
    showDate?: boolean;
    showAuthor?: boolean;
    gridVariant?: 'variant-a' | 'variant-b' | 'variant-c';
    colors?: 'colors-a' | 'colors-b' | 'colors-c';
  };
  backToTopButton?: boolean;
  index?: boolean;
  bottomSections?: any[];
  topSections?: any[];
  seo?: any;
}>();

const router = useRouter();
const route = useRoute();
const { locale } = useI18n();
const localePath = useLocalePath();
const { pathname, searchParams } = useRequestURL();

const colors = computed(() => postFeed?.colors || 'colors-a');
const gridVariant = computed(() => postFeed?.gridVariant || 'variant-a');
const numberOfPostsPerPage = computed(
  () => postFeed?.numberOfPostsPerPage ?? 10
);
const paginationVariant = computed(
  () => postFeed?.paginationVariant || 'Old-school'
);
const showAuthor = computed(() => postFeed?.showAuthor ?? true);
const showDate = computed(() => postFeed?.showDate ?? true);
const showExcerpt = computed(() => postFeed?.showExcerpt ?? false);
const elementId = computed(() => postFeed?.elementId || '');
const showFilters = computed(() => postFeed?.showFilters ?? false);
const styles = computed(() => postFeed?.styles);

const firstRenderLoading = ref(true);

const postsPerPage = computed(() =>
  numberOfPostsPerPage.value === 0 ? 9999 : numberOfPostsPerPage.value
);

const currentPostsPage = ref(route.query?.page ? +route.query.page : 1);
const paginationOffset = ref(
  postsPerPage.value * currentPostsPage.value - postsPerPage.value
);

const allPages = useLocalStorage('pages', []);
const storedTags = useLocalStorage('tags', []);

const localPosts = computed(() =>
  allPages.value.filter(
    (el) =>
      el.type === 'PostLayout' &&
      el.slug.startsWith(pathname.split('/').splice(-1)[0])
  )
);

const initialTags = computed(() =>
  Array.from(
    localPosts.value
      .map((post) => post.tags)
      .flat()
      .reduce(
        (tagCounts, tag) => tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1),
        new Map()
      ),
    ([name, count]: [string, number]) => ({
      id: name,
      name:
        storedTags.value.find((tag) => tag.id === name)?.name ||
        'Incorrect tag ⚠️',
      count,
      active: route.query?.tags
        ? (route.query.tags as string).split(',').some((tag) => tag === name)
        : false,
    })
  )
);

const tags = ref<typeof initialTags.value>(toJS(initialTags.value));

const activeTagIds = computed(() =>
  tags.value.filter((tag) => tag.active).length
    ? tags.value.filter((tag) => tag.active).map((tag) => tag.id)
    : tags.value.map((tag) => tag.id)
);

const postsIds = computed(() =>
  localPosts.value
    .map((post) => post.id)
    .splice(paginationOffset.value, postsPerPage.value)
);
const { data: posts, pending } = await useLazyFetch('/api/posts', {
  query: {
    ids: postsIds,
    tags: activeTagIds,
    locale: locale.value,
  },
});

const postsPageCount = computed(() =>
  Math.ceil(localPosts.value.length / postsPerPage.value)
);

// Might be better than other offset
// const offsetTest = computed(
//   () => (currentPostsPage.value - 1) * postsPerPage.value + 1
// );

const changePage = (pageNumber?: number, mark?: '+' | '-') => {
  if (!mark) currentPostsPage.value = pageNumber;
  if (mark === '+') currentPostsPage.value++;
  if (mark === '-') currentPostsPage.value--;

  paginationOffset.value =
    postsPerPage.value * currentPostsPage.value - postsPerPage.value;

  if (currentPostsPage.value === 1) {
    router.push({
      query: { page: undefined, tags: route.query?.tags },
    });
  } else {
    router.push({
      query: { page: currentPostsPage.value, tags: route.query?.tags },
    });
  }
};

const activateTag = (idx: number) => {
  tags.value[idx].active = !tags.value[idx].active;
  router.push({
    query: {
      page: route.query?.page,
      tags: tags.value?.some((tag) => tag.active)
        ? activeTagIds.value?.join(',')
        : undefined,
    },
  });
};

const clearFilters = () => {
  tags.value.forEach((tag) => void (tag.active = false));
  router.push({
    query: { page: route.query?.page, tags: undefined },
  });
};

// watch(
//   () => route.query,
//   () => {
//     // route.query?.tags ? (route.query.tags as string).split(',').length === 1 ? tags.value.forEach((tag, idx) => tags.value[idx].active = false) :  :
//   }
// );

onBeforeMount(() => {
  router.push({
    query: {
      page: route.query?.page === '1' ? undefined : route.query?.page,
      tags: route.query?.tags,
    },
  });
});

onMounted(() => {
  firstRenderLoading.value = false;
});
</script>

<style scoped lang="postcss"></style>
