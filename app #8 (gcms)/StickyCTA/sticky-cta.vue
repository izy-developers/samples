<template>
  <div
    v-if="stickyContent.length && includePages?.includes(route.path)"
    :class="[
      isContentShowWithScroll && scrolled && 'translate-y-full',
      translateHeightHidden && scrolled && 'translate-y-full',
    ]"
    class="space-y-6 bg-white p-4 fixed bottom-0 w-full shadow-[0_5px_15px] shadow-black z-10 transition-all"
  >
    <PrimitiveButton
      v-for="(item, idx) in stickyContent"
      wrapperClass="w-full"
      v-bind="item"
      :key="idx"
    />
  </div>
</template>

<script setup lang="ts">
const { isContentShowWithScroll = false, } = defineProps<{
  stickyContent?: any;
  isContentShowWithScroll?: boolean;
  internalName?: string;
  annotationPrefix?: any;
  includePages?: string[];
  __metadata?: any;
}>();

const route = useRoute()
const { y } = useWindowScroll();
const { height } = useWindowSize();

const scrolled = ref(true);
const translateHeightHidden = ref(false);

watchDebounced(
  y,
  () => {
    if (y.value < 800) scrolled.value = true;
    else if (y.value + height.value >= document.documentElement.scrollHeight) {
      translateHeightHidden.value = true;
      scrolled.value = true;
    } else {
      translateHeightHidden.value = false;
      scrolled.value = false;
    }
  },
  { debounce: 200, maxWait: 400 },
);
</script>

<style scoped lang="postcss">
.bio-component-button-primary {
  @apply bg-secondary text-on-primary;
}
.bio-component-button-secondary {
  @apply bg-secondary text-secondary hover:bg-secondary;
}
.bio-component-button-outlined {
  @apply border-grey text-grey;
}
</style>
