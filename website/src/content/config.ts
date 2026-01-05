import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const docs = defineCollection({
  loader: glob({
    pattern: '**/*.md',
    base: '../docs'
  }),
  schema: z.object({}).optional()
});

export const collections = { docs };
