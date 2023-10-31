<template>
  <component
    :is="asButton ? 'button' : NuxtLink"
    :rel="follow ? 'follow' : 'nofollow'"
    :type="typeButton"
    :to="
      !asButton
        ? fileLink || isExternalUrl(url)
          ? getFileUrl(fileLink) || url
          : $urlWithQuery(url)
        : undefined
    "
    :aria-label="altText"
    :data-sb-field-path="annotations.join(' ').trim()"
    :class="[
      'bio-component-button',
      overwriteButtonColor,
      {
        'bio-component-button-primary': styleButton === 'primary',
        'bio-component-button-secondary': styleButton === 'secondary',
        'bio-component-button-outlined': styleButton === 'outlined',
        'rounded-full': rounded,
      },
      wrapperClass,
    ]"
    :style="buttonStyles"
  >
    <template v-if="loading">
      <svg
        class="-ml-1 mr-3 h-5 w-5 animate-spin text-white"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle
          class="opacity-25"
          cx="12"
          cy="12"
          r="10"
          stroke="currentColor"
          stroke-width="4"
        ></circle>
        <path
          class="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        ></path>
      </svg>
      Loading...
    </template>
    <template v-else>
      <span v-if="label">
        {{ label }}
      </span>

      <PrimitiveIcon
        :icon="icon"
        :showIcon="showIcon"
        :fill-icon="fillIcon"
        :classIcon="[
          {
            'order-first': iconPosition === 'left',
            '-ml-1 mr-3': label && iconPosition === 'left',
            'ml-3 -mr-1': label && iconPosition === 'right',
          },
        ]"
      />
    </template>
  </component>
</template>

<script setup lang="ts">
import { NuxtLink } from '#components';

const {
  annotationPrefix = '',
  altText = '',
  styleButton = 'primary',
  overwriteButtonColor = 'inherit',
  rounded = false,
  icon = 'arrowLeft',
  iconPosition = 'right',
  fillIcon = true,
  asButton = false,
  increaseButtonWidth = 'default',
  loading = false,
  url = '/',
} = defineProps<{
  follow?: boolean;
  url?: string;
  label?: string;
  altText?: string;
  styleButton?: 'primary' | 'outlined' | 'secondary';
  increaseButtonWidth?: 'default' | '1.5' | '2' | '3';
  loading?: boolean;
  icon?: string;
  showIcon?: boolean;
  iconPosition?: string;
  fillIcon?: boolean;
  rounded?: boolean;
  annotationPrefix?: string;
  wrapperClass?: any;
  fileLink?: any;
  typeButton?: string;
  asButton?: boolean;
  overwriteButtonColor?:
    | 'btn-color-primary'
    | 'btn-color-secondary'
    | 'btn-color-complementary'
    | 'inherit';
  __metadata?: any;
}>();

const paddingMultiplier = computed(
  () =>
    ({ default: 'default', '1.5': 1.5, '2': 2, '3': 3 })[increaseButtonWidth],
);

const buttonStyles = computed(() =>
  paddingMultiplier.value !== 'default'
    ? {
        ...(styleButton === 'primary'
          ? {
              paddingRight: `calc(var(--button-primary-x-padding)*${paddingMultiplier.value})`,
              paddingLeft: `calc(var(--button-primary-x-padding)*${paddingMultiplier.value})`,
            }
          : styleButton === 'secondary'
          ? {
              paddingRight: `calc(var(--button-secondary-x-padding)*${paddingMultiplier.value})`,
              paddingLeft: `calc(var(--button-secondary-x-padding)*${paddingMultiplier.value})`,
            }
          : styleButton === 'outlined'
          ? {
              paddingRight: `calc(var(--button-outlined-x-padding)*${paddingMultiplier.value})`,
              paddingLeft: `calc(var(--button-outlined-x-padding)*${paddingMultiplier.value})`,
            }
          : {}),
      }
    : undefined,
);

const annotations = [
  `${annotationPrefix}`,
  `${annotationPrefix}.url#@href`,
  `${annotationPrefix}.altText#@aria-label`,
  `${annotationPrefix}.label#span[1]`,
  `${annotationPrefix}.follow#@rel`,
];
</script>

<style scoped lang="postcss">
.bio-component-button {
  &:where([class~='bg-color-none'] *),
  &:where([class~='bg-color-addit-a'] *),
  &:where([class~='bg-color-addit-b'] *),
  &:where([class~='bg-color-addit-c'] *) {
    &.btn-color-primary {
      &.bio-component-button-primary {
        @apply !bg-primary !text-on-primary;
      }
      &.bio-component-button-secondary {
        @apply !bg-primary !text-primary hover:!bg-primary;
      }
      &.bio-component-button-outlined {
        @apply !border-primary !text-primary;
      }
    }
    &.btn-color-secondary {
      &.bio-component-button-primary {
        @apply !bg-secondary !text-on-secondary;
      }
      &.bio-component-button-secondary {
        @apply !bg-secondary !text-secondary hover:!bg-secondary;
      }
      &.bio-component-button-outlined {
        @apply !border-secondary !text-secondary;
      }
    }
    &.btn-color-complementary {
      &.bio-component-button-primary {
        @apply !bg-complementary !text-on-complementary;
      }
      &.bio-component-button-secondary {
        @apply !bg-complementary !text-complementary hover:!bg-complementary;
      }
      &.bio-component-button-outlined {
        @apply !border-complementary !text-complementary;
      }
    }
  }

  &:where([class~='bg-color-primary'] *),
  &:where([class~='bg-color-secondary'] *),
  &:where([class~='bg-color-complementary'] *) {
    &.btn-color-primary.bio-component-button-primary {
      @apply !text-primary;
    }
    &.btn-color-secondary.bio-component-button-primary {
      @apply !text-secondary;
    }
    &.btn-color-complementary.bio-component-button-primary {
      @apply !text-complementary;
    }
  }
}
</style>
