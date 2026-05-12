import mongoose, { Document, Schema } from 'mongoose'

export interface IPost extends Document {
  _id: mongoose.Types.ObjectId
  title: string
  slug: string
  content: string
  excerpt: string
  coverImage?: string
  author: mongoose.Types.ObjectId
  tags: string[]
  status: 'draft' | 'published'
  views: number
  likes: mongoose.Types.ObjectId[]
  createdAt: Date
  updatedAt: Date
}

const postSchema = new Schema<IPost>(
  {
    title: { type: String, required: true, trim: true, maxlength: 150 },
    slug: { type: String, unique: true, lowercase: true },
    content: { type: String, required: true },
    excerpt: { type: String, maxlength: 300 },
    coverImage: { type: String, default: '' },
    author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    tags: [{ type: String, lowercase: true, trim: true }],
    status: { type: String, enum: ['draft', 'published'], default: 'draft' },
    views: { type: Number, default: 0 },
    likes: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
)

postSchema.pre('save', function (next) {
  if (this.isModified('title')) {
    this.slug = this.title.toLowerCase().replace(/[^a-z0-9 ]/g, '').replace(/\s+/g, '-').slice(0, 80) + '-' + Date.now()
  }
  if (this.isModified('content') && !this.excerpt) {
    this.excerpt = this.content.replace(/<[^>]*>/g, '').slice(0, 200) + '...'
  }
  next()
})

postSchema.index({ title: 'text', content: 'text', tags: 'text' })
postSchema.index({ slug: 1 })
postSchema.index({ author: 1, status: 1 })

export default mongoose.model<IPost>('Post', postSchema)
