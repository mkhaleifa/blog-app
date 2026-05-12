import { Response } from 'express'
import { validationResult } from 'express-validator'
import Post from '../models/Post'
import { AuthRequest } from '../middleware/auth'

export const getPosts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1
    const limit = parseInt(req.query.limit as string) || 10
    const skip = (page - 1) * limit
    const tag = req.query.tag as string
    const search = req.query.search as string
    const query: Record<string, unknown> = { status: 'published' }
    if (tag) query.tags = tag
    if (search) query.$text = { $search: search }
    const [posts, total] = await Promise.all([
      Post.find(query).populate('author', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(limit).select('-content'),
      Post.countDocuments(query),
    ])
    res.json({ success: true, data: posts, pagination: { page, limit, total, pages: Math.ceil(total / limit) } })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const getPost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findOne({ slug: req.params.slug, status: 'published' }).populate('author', 'name avatar bio')
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    post.views += 1
    await post.save()
    res.json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const createPost = async (req: AuthRequest, res: Response): Promise<void> => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) { res.status(400).json({ success: false, errors: errors.array() }); return }
  try {
    const { title, content, excerpt, coverImage, tags, status } = req.body
    const post = await Post.create({ title, content, excerpt, coverImage, tags: tags || [], status: status || 'draft', author: req.user?._id })
    res.status(201).json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error creating post' }) }
}

export const updatePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    if (post.author.toString() !== req.user?._id.toString()) {
      res.status(403).json({ success: false, message: 'Not authorized to edit this post' }); return
    }
    const { title, content, excerpt, coverImage, tags, status } = req.body
    if (title) post.title = title
    if (content) post.content = content
    if (excerpt) post.excerpt = excerpt
    if (coverImage !== undefined) post.coverImage = coverImage
    if (tags) post.tags = tags
    if (status) post.status = status
    await post.save()
    res.json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error updating post' }) }
}

export const deletePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    if (post.author.toString() !== req.user?._id.toString()) {
      res.status(403).json({ success: false, message: 'Not authorized to delete this post' }); return
    }
    await post.deleteOne()
    res.json({ success: true, message: 'Post deleted successfully' })
  } catch { res.status(500).json({ success: false, message: 'Server error deleting post' }) }
}

export const getMyPosts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const posts = await Post.find({ author: req.user?._id }).sort({ createdAt: -1 })
    res.json({ success: true, data: posts })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const likePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    const userId = req.user?._id
    const alreadyLiked = post.likes.some(id => id.toString() === userId?.toString())
    if (alreadyLiked) {
      post.likes = post.likes.filter(id => id.toString() !== userId?.toString())
    } else {
      post.likes.push(userId!)
    }
    await post.save()
    res.json({ success: true, likes: post.likes.length, liked: !alreadyLiked })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}
